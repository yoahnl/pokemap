import 'package:flutter/cupertino.dart';

/// Every glyph the Avelune surfaces are allowed to draw.
///
/// Named by role rather than by shape, so a component asks for
/// [AveluneIcons.settings] and never for a particular drawing. Swapping the set
/// again — for a bespoke one, say — is then a change to this file alone.
///
/// The set is Cupertino: Material's glyphs carry Material's voice, and rounded
/// filled pictograms sit badly against glass and a photoreal room.
abstract final class AveluneIcons {
  // Navigation and chrome.
  static const IconData home = CupertinoIcons.house_fill;
  static const IconData settings = CupertinoIcons.gear_solid;
  static const IconData profile = CupertinoIcons.person;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData back = CupertinoIcons.chevron_back;
  static const IconData forward = CupertinoIcons.chevron_forward;
  static const IconData details = CupertinoIcons.info_circle;

  // The console and its cartridges.
  static const IconData insert = CupertinoIcons.arrow_down;
  static const IconData game = CupertinoIcons.game_controller_solid;
  static const IconData addGame = CupertinoIcons.add;
  static const IconData exchange = CupertinoIcons.arrow_left_right;
  static const IconData brand = CupertinoIcons.moon_stars;

  // Appearance.
  static const IconData appearance = CupertinoIcons.circle_lefthalf_fill;
  static const IconData background = CupertinoIcons.photo;
  static const IconData furniture = CupertinoIcons.square_grid_2x2;
  static const IconData ownImage = CupertinoIcons.photo_on_rectangle;
  static const IconData files = CupertinoIcons.folder;
  static const IconData selected = CupertinoIcons.checkmark_alt;
  static const IconData remove = CupertinoIcons.delete;

  // Storage, motion, diagnostics.
  static const IconData storage = CupertinoIcons.cube_box;
  static const IconData storageUsed = CupertinoIcons.archivebox;
  static const IconData storageFree = CupertinoIcons.tray;
  static const IconData motion = CupertinoIcons.wand_stars;
  static const IconData motionOn = CupertinoIcons.sparkles;
  static const IconData motionReduced = CupertinoIcons.slash_circle;
  static const IconData diagnostics = CupertinoIcons.waveform_path_ecg;
  static const IconData integrity = CupertinoIcons.checkmark_shield;
  static const IconData copy = CupertinoIcons.doc_on_doc;
  static const IconData pending = CupertinoIcons.hourglass;

  // States.
  static const IconData error = CupertinoIcons.exclamationmark_circle;
  static const IconData warning = CupertinoIcons.exclamationmark_triangle;
  static const IconData missingImage = CupertinoIcons.photo;
  static const IconData viewport = CupertinoIcons.fullscreen;
}
