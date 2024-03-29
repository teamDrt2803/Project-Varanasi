import 'package:another_flushbar/flushbar_helper.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiosaavn_wrapper/src-v2/src-v2.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:varanasi/common/audio_handler.dart';
import 'package:varanasi/controllers/index.dart';
import 'package:varanasi/custom/cust_rx.dart';
import 'package:varanasi/routes/routes.dart';
import 'package:varanasi/utils/constants.dart';
import 'package:varanasi/utils/extensions.dart';

class PlayerController extends GetxController {
  late AudioHandler audioHandler;
  InstrumentPool instrumentPool = Get.find();
  SongController songController = Get.find();
  AudioPlayer audioPlayer = AudioPlayer();
  RxnMediaItem currSong = RxnMediaItem();
  RxBool playingStream = RxBool(false);
  RxBool shuffleModeStrem = RxBool(false);
  Rx<PlaybackEvent> playBackStream = Rx(PlaybackEvent());
  RxList<MediaItem> queueStream = RxList();
  Rxn<CachedNetworkImageProvider> cachedNetworkImageProvider = Rxn();
  Rxn<PaletteGenerator> paletteGenerator = Rxn();
  PageController fullScreenThumbController = PageController(keepPage: false);
  Rx<Duration> positionStream = Rx(Duration.zero);
  RxnString currentParentId = RxnString();
  RxBool loader = RxBool(false);
  Rx<LoopMode> loopMode = Rx(LoopMode.off);

  MediaItem? get currentSong => currSong.value;
  bool get isSongSelected => currentSong != null;
  bool get isPlaying => playingStream.value;
  bool get isBuffering =>
      playBackStream.value.processingState == ProcessingState.buffering ||
      loader.value;
  bool get hasNext => audioPlayer.hasNext;
  bool get hasPrev => audioPlayer.hasPrevious;
  bool get isShuffleModeEnabled => shuffleModeStrem.value;
  Color? get topColor => paletteGenerator.value?.mutedColor?.color;
  Color? get bottomColor =>
      paletteGenerator.value?.darkMutedColor?.color ?? topColor;
  Color? get textColor =>
      paletteGenerator.value?.darkMutedColor?.bodyTextColor.withOpacity(1) ??
      paletteGenerator.value?.mutedColor?.bodyTextColor.withOpacity(1);
  Duration get currentSongPosition => positionStream.value;
  Future<void> handleSeek(Duration p) async => audioHandler.seek(p);
  Future<void> toggleShuffleMode() =>
      audioHandler.setShuffleMode(isShuffleModeEnabled
          ? AudioServiceShuffleMode.none
          : AudioServiceShuffleMode.all);
  BuildContext? get context => Get.context;
  IconData get repeatIcon {
    return {
      LoopMode.all: Icons.repeat_on_outlined,
      LoopMode.off: Icons.repeat,
      LoopMode.one: Icons.repeat_one_on_outlined
    }[loopMode.value]!;
  }

  Future<void> skipNext() => audioHandler.skipToNext();
  Future<void> skipPrevious() => audioHandler.skipToPrevious();
  Future<void> play() => isPlaying ? audioHandler.pause() : audioHandler.play();
  Future<void> chanageRepeatMode() => audioHandler.setRepeatMode({
        LoopMode.all: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.all,
        LoopMode.off: AudioServiceRepeatMode.one
      }[loopMode.value]!);

  @override
  Future<void> onReady() async {
    super.onReady();
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: ConstantStrings.notificationChanelId,
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
    await audioHandler.prepare();
    ever(shuffleModeStrem, _handleShuffleModeChange);
    ever(currSong, _handleCurrentMediaItemUpdate);
    loopMode.bindStream(audioPlayer.loopModeStream);
    shuffleModeStrem.bindStream(audioPlayer.shuffleModeEnabledStream);
    currSong.bindStream(audioHandler.mediaItem);
    playingStream.bindStream(audioPlayer.playingStream);
    playBackStream.bindStream(audioPlayer.playbackEventStream);
    queueStream.bindStream(audioHandler.queue);
    positionStream.bindStream(audioPlayer.positionStream);
  }

  void showFullScreenPlayer() =>
      Get.find<AppController>().toNamed(Routes.fullScreenPlayer);

  void selectSong(Song song, String parentId) async {
    if (song.isMinified) return;
    loader.value = true;
    var currentSong = song.mediaItem;
    if (this.currentSong == null) {
      currSong.value = currentSong;
    }
    if (parentId != currentParentId.value && parentId.isNotEmpty) {
      var data = instrumentPool.getCachedDataWithoutType(parentId);
      var songs = songController.getSongList(data);
      currentParentId.value = parentId;
      await audioHandler.addQueueItems(songs.map((e) => e.mediaItem).toList());
      await playFromId(currentSong.id);
    } else {
      bool isSelected = this.currentSong?.id == song.mediaURL;
      bool alreadyAdded = queueStream.any((e) => e.id == currentSong.id);
      if (!alreadyAdded) {
        await audioHandler.addQueueItem(currentSong);
      }
      if (!isSelected) {
        playFromId(currentSong.id);
      } else {
        isPlaying ? audioHandler.pause() : audioHandler.play();
      }
    }
    loader.value = false;
  }

  Future<void> playFromId(String id) async =>
      await audioHandler.playFromMediaId(id);

  Future<void> _handleCurrentMediaItemUpdate(MediaItem? mediaItem) async {
    if (mediaItem != null) {
      debugPrint('Updated Current Song');
      cachedNetworkImageProvider.value =
          CachedNetworkImageProvider(mediaItem.artUri.toString());
      if (cachedNetworkImageProvider.value != null) {
        paletteGenerator.value = await PaletteGenerator.fromImageProvider(
          cachedNetworkImageProvider.value!,
        );
      }
    }
  }

  void _handleShuffleModeChange(bool enabled) {
    FlushbarHelper.createInformation(
            message: '${enabled ? 'Enabled' : 'Disabled'} shuffle mode')
        .show(context!);
  }
}
