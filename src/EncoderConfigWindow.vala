/*
 * ConfigWindow.vala
 *
 * Copyright 2012 Tony George <teejee2008@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using Gtk;
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class EncoderConfigWindow : Gtk.Dialog {

	private string Folder = "";
	private string Name = "";
	private bool IsNew = true;

	private Notebook tabMain;
	private Box vboxMain;

	private Label lblGeneral;
	private Grid gridGeneral;

	private Label lblVideo;
	private Grid gridVideo;

	private Label lblAudio;
	private Grid gridAudio;

	private Label lblSubtitle;
	private Grid gridSubtitle;

	private Label lblVideoFilters;
	private Grid gridVideoFilters;

	private Label lblAudioFilters;
	private Grid gridAudioFilters;

	private Label lblPresetName;
	private Entry txtPresetName;

	private Label lblFileFormat;
	private ComboBox cmbFileFormat;

	private Label lblFileExtension;
	private ComboBox cmbFileExtension;

	private Label lblVCodec;
	private ComboBox cmbVCodec;
	private Label lblVCodecMessage;

	private Label lblVideoMode;
	private ComboBox cmbVideoMode;

	private Label lblVideoBitrate;
	private SpinButton spinVideoBitrate;

	private ComboBox cmbX264Preset;
	private Label lblX264Preset;

	private Label lblX264Profile;
	private ComboBox cmbX264Profile;

	private Label lblVideoQuality;
	private SpinButton spinVideoQuality;

	private ComboBox cmbVpxSpeed;
	private Label lblVpxSpeed;
	private Scale scaleVpxSpeed;

	private Label lblHeaderFileFormat;
	private Label lblHeaderPreset;
	private Label lblHeaderFrameSize;
	private Label lblHeaderFrameRate;

	private Gtk.Image imgAudioCodec;
	private Gtk.Image imgVideoCodec;
	private Gtk.Image imgFileFormat;

	private Label lblFrameSize;
	private ComboBox cmbFrameSize;
	private Label lblFrameSizeCustom;
	private SpinButton spinFrameWidth;
	private SpinButton spinFrameHeight;
	private Box hboxFrameSize;
	private CheckButton chkNoUpScale;
	private CheckButton chkFitToBox;

	private Label lblFPS;
	private ComboBox cmbFPS;
	private Label lblFPSCustom;
	private SpinButton spinFPSNum;
	private SpinButton spinFPSDenom;
	private Box hboxFPS;
	private Label lblResizingMethod;
	private ComboBox cmbResizingMethod;

	private Label lblVCodecOptions;
	private Gtk.TextView txtVCodecOptions;

	private Label lblACodec;
	private ComboBox cmbACodec;
	private Label lblACodecMessage;
	
	private Label lblAudioMode;
	private ComboBox cmbAudioMode;

	private Label lblAudioBitrate;
	private SpinButton spinAudioBitrate;

	private Label lblAudioQuality;
	private SpinButton spinAudioQuality;

	private Label lblOpusOptimize;
	private ComboBox cmbOpusOptimize;

	private Label lblAacProfile;
	private ComboBox cmbAacProfile;
	
	private Label lblAuthorName;
	private Entry txtAuthorName;

	private Label lblAuthorEmail;
	private Entry txtAuthorEmail;

	private Label lblPresetVersion;
	private Entry txtPresetVersion;

	private Label lblAudioSampleRate;
	private ComboBox cmbAudioSampleRate;

	private Label lblAudioChannels;
	private ComboBox cmbAudioChannels;

	private Switch switchSox;
	private Box vboxSoxOuter;
	private Label lblHeaderSox;
	private Label lblAudioBass;
	private Scale scaleBass;
	private Label lblAudioTreble;
	private Scale scaleTreble;
	private Label lblAudioPitch;
	private Scale scalePitch;
	private Label lblAudioTempo;
	private Scale scaleTempo;
	private Label lblNormalize;
	private Switch switchNormalize;
	private Label lblEarWax;
	private Switch switchEarWax;
	private Label lblFadeIn;
	private SpinButton spinFadeIn;
	private Label lblFadeOut;
	private SpinButton spinFadeOut;
	private ComboBox cmbFadeType;

	private Label lblSubtitleMode;
	private ComboBox cmbSubtitleMode;

	private Label lblSubFormatMessage;

	private uint tmr_init = 0;
	
	private Button btnSave;
	private Button btnCancel;

	public EncoderConfigWindow.from_preset(Gtk.Window parent, string _folder, string _name, bool _is_new){
		set_transient_for(parent);
		set_modal(true);
		
		Folder = _folder;
		Name = _name;
		IsNew = _is_new;
		
		init_ui();
	}
	
	private void init_ui() {
		title = "Preset";
		set_default_size (450, 550);

		window_position = WindowPosition.CENTER_ON_PARENT;
		destroy_with_parent = true;
		skip_taskbar_hint = true;
		modal = true;
		icon = get_app_icon(16);

		this.delete_event.connect(on_delete_event);

		//get content area
		vboxMain = get_content_area();

		//tabMain
		tabMain = new Notebook();
		tabMain.tab_pos = PositionType.TOP;
		tabMain.show_border = true;
		tabMain.scrollable = true;
		tabMain.margin = 6;
		vboxMain.pack_start (tabMain, true, true, 0);

		//styles ---------------------------------------------------

		/*string css_style = """
            GtkNotebook tab {
				padding: 1px;
			}
        """;//color: #703910;

		CssProvider css_provider = new CssProvider();
        try {
            css_provider.load_from_data(css_style,-1);
            Gtk.StyleContext.add_provider_for_screen(this.get_screen(),css_provider,Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (GLib.Error e) {
            warning(e.message);
        }*/

        /* Note: Setting tab button padding to 0 causes problems with some GTK themes like Mint-X */

		// add widgets ---------------------------------------------

		init_ui_general();

		init_ui_video();

		init_ui_video_filters();

		init_ui_audio();

		init_ui_audio_filters();

		init_ui_sox();
		
		init_ui_subtitles();

		// Actions ----------------------------------------------

        //btnSave
        btnSave = (Button) add_button ("gtk-save", Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (btnSave_clicked);

        //btnCancel
        btnCancel = (Button) add_button ("gtk-cancel", Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (() => { destroy(); });

		show_all();

        tmr_init = Timeout.add(100, init_delayed);
	}

	private void init_ui_general(){
		//lblGeneral
		lblGeneral = new Label (_("General"));

		//gridGeneral
		gridGeneral = new Grid();
		gridGeneral.set_column_spacing (6);
		gridGeneral.set_row_spacing (6);
		gridGeneral.margin = 12;
		gridGeneral.visible = false;
		tabMain.append_page (gridGeneral, lblGeneral);

		int row = -1;
		//string tt = "";
		Gtk.ListStore model;
		TreeIter iter;

		//lblHeaderFileFormat
		lblHeaderFileFormat = new Gtk.Label(_("<b>File Format:</b>"));
		lblHeaderFileFormat.set_use_markup(true);
		lblHeaderFileFormat.xalign = (float) 0.0;
		//lblHeaderFileFormat.margin_top = 6;
		lblHeaderFileFormat.margin_bottom = 6;
		gridGeneral.attach(lblHeaderFileFormat,0,++row,2,1);

		//lblFileFormat
		lblFileFormat = new Gtk.Label(_("Format"));
		lblFileFormat.xalign = (float) 0.0;
		gridGeneral.attach(lblFileFormat,0,++row,1,1);

		//cmbFileFormat
		model = new Gtk.ListStore (2, typeof (string), typeof (string));

		model.append (out iter);
		model.set (iter,0,_("Matroska Video (*.mkv)"),1,"mkv");
		model.append (out iter);
		model.set (iter,0,_("MPEG4 Video (*.mp4)"),1,"mp4v");
		model.append (out iter);
		model.set (iter,0,_("OGG Theora Video (*.ogv)"),1,"ogv");
		model.append (out iter);
		model.set (iter,0,_("WebM Video (*.webm)"),1,"webm");
		model.append (out iter);
		model.set (iter,0,_("AC3 Audio (*.ac3)"),1,"ac3");
		model.append (out iter);
		model.set (iter,0,_("FLAC Audio (*.flac)"),1,"flac");
		model.append (out iter);
		model.set (iter,0,_("MP3 Audio (*.mp3)"),1,"mp3");
		model.append (out iter);
		model.set (iter,0,_("MP4 Audio (*.mp4)"),1,"mp4a");
		model.append (out iter);
		model.set (iter,0,_("OGG Vorbis Audio (*.ogg)"),1,"ogg");
		model.append (out iter);
		model.set (iter,0,_("Opus Audio (*.opus)"),1,"opus");
		model.append (out iter);
		model.set (iter,0,_("WAV Audio (*.wav)"),1,"wav");

		cmbFileFormat = new ComboBox.with_model(model);
		var textCell = new CellRendererText();
        cmbFileFormat.pack_start( textCell, false );
        cmbFileFormat.set_attributes( textCell, "text", 0 );
        cmbFileFormat.changed.connect(cmbFileFormat_changed);
        gridGeneral.attach(cmbFileFormat,1,row,1,1);

        //lblFileExtension
		lblFileExtension = new Gtk.Label(_("Extension"));
		lblFileExtension.xalign = (float) 0.0;
		gridGeneral.attach(lblFileExtension,0,++row,1,1);

		cmbFileExtension = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbFileExtension.pack_start( textCell, false );
        cmbFileExtension.set_attributes( textCell, "text", 0 );
        gridGeneral.attach(cmbFileExtension,1,row,1,1);

        //lblHeaderPreset
		lblHeaderPreset = new Gtk.Label(_("<b>Preset:</b>"));
		lblHeaderPreset.set_use_markup(true);
		lblHeaderPreset.xalign = (float) 0.0;
		lblHeaderPreset.margin_top = 6;
		lblHeaderPreset.margin_bottom = 6;
		gridGeneral.attach(lblHeaderPreset,0,++row,2,1);

        //lblPresetName
		lblPresetName = new Gtk.Label(_("Name"));
		lblPresetName.xalign = (float) 0.0;
		gridGeneral.attach(lblPresetName,0,++row,1,1);

		//txtPresetName
		txtPresetName = new Gtk.Entry();
		txtPresetName.xalign = (float) 0.0;
		txtPresetName.text = _("New Preset");
		txtPresetName.hexpand = true;
		gridGeneral.attach(txtPresetName,1,row,1,1);

		//lblPresetVersion
		lblPresetVersion = new Gtk.Label(_("Version"));
		lblPresetVersion.xalign = (float) 0.0;
		gridGeneral.attach(lblPresetVersion,0,++row,1,1);

		//txtPresetVersion
		txtPresetVersion = new Gtk.Entry();
		txtPresetVersion.xalign = (float) 0.0;
		txtPresetVersion.text = "1.0";
		gridGeneral.attach(txtPresetVersion,1,row,1,1);

        //lblAuthorName
		lblAuthorName = new Gtk.Label(_("Author"));
		lblAuthorName.xalign = (float) 0.0;
		gridGeneral.attach(lblAuthorName,0,++row,1,1);

		//txtAuthorName
		txtAuthorName = new Gtk.Entry();
		txtAuthorName.xalign = (float) 0.0;
		txtAuthorName.text = "";
		gridGeneral.attach(txtAuthorName,1,row,1,1);

		//lblAuthorEmail
		lblAuthorEmail = new Gtk.Label(_("Email"));
		lblAuthorEmail.xalign = (float) 0.0;
		gridGeneral.attach(lblAuthorEmail,0,++row,1,1);

		//txtAuthorEmail
		txtAuthorEmail = new Gtk.Entry();
		txtAuthorEmail.xalign = (float) 0.0;
		txtAuthorEmail.text = "";
		gridGeneral.attach(txtAuthorEmail,1,row,1,1);

		//imgFileFormat
		imgFileFormat = new Gtk.Image();
		imgFileFormat.margin_top = 6;
		imgFileFormat.margin_bottom = 6;
		imgFileFormat.expand = true;
        gridGeneral.attach(imgFileFormat,0,++row,2,1);
	}
	
	private void init_ui_audio(){
		//lblAudio
		lblAudio = new Label (_("Audio"));

        //gridAudio
        gridAudio = new Grid();
        gridAudio.set_column_spacing (6);
        gridAudio.set_row_spacing (6);
        gridAudio.margin = 12;
        gridAudio.visible = false;
        tabMain.append_page (gridAudio, lblAudio);

		int row = -1;
		//string tt = "";
		Gtk.ListStore model;
		TreeIter iter;

		//lblACodec
		lblACodec = new Gtk.Label(_("Format / Codec"));
		lblACodec.xalign = (float) 0.0;
		gridAudio.attach(lblACodec,0,++row,1,1);

		//cmbACodec
		cmbACodec = new ComboBox();
		var textCell = new CellRendererText();
        cmbACodec.pack_start(textCell, false);
        cmbACodec.set_attributes(textCell, "text", 0);
        cmbACodec.changed.connect(cmbACodec_changed);
        cmbACodec.hexpand = true;
        gridAudio.attach(cmbACodec,1,row,1,1);

		//lblACodecMessage
		lblACodecMessage = new Gtk.Label("");
		lblACodecMessage.xalign = (float) 0.0;
		lblACodecMessage.no_show_all = true;
		lblACodecMessage.wrap = true;
		lblACodecMessage.wrap_mode = Pango.WrapMode.WORD;
		lblACodecMessage.use_markup = true;
		gridAudio.attach(lblACodecMessage,0,++row,2,1);
		
		//lblAudioMode
		lblAudioMode = new Gtk.Label(_("Encoding Mode"));
		lblAudioMode.xalign = (float) 0.0;
		gridAudio.attach(lblAudioMode,0,++row,1,1);

		//cmbAudioMode
		cmbAudioMode = new ComboBox();
		textCell = new CellRendererText();
        cmbAudioMode.pack_start(textCell, false);
        cmbAudioMode.set_attributes(textCell, "text", 0);
        cmbAudioMode.changed.connect(cmbAudioMode_changed);
        gridAudio.attach(cmbAudioMode,1,row,1,1);

		//lblAudioBitrate
		lblAudioBitrate = new Gtk.Label(_("Bitrate (kbps)"));
		lblAudioBitrate.xalign = (float) 0.0;
		gridAudio.attach(lblAudioBitrate,0,++row,1,1);

		//spinAudioBitrate
		Gtk.Adjustment adjAudioBitrate = new Gtk.Adjustment(128, 32, 320, 1, 1, 0);
		spinAudioBitrate = new Gtk.SpinButton (adjAudioBitrate, 1, 0);
		spinAudioBitrate.xalign = (float) 0.5;
		gridAudio.attach(spinAudioBitrate,1,row,1,1);

		//lblAudioQuality
		lblAudioQuality = new Gtk.Label(_("Quality"));
		lblAudioQuality.xalign = (float) 0.0;
		gridAudio.attach(lblAudioQuality,0,++row,1,1);

		//spinAudioQuality
		Gtk.Adjustment adjAudioQuality = new Gtk.Adjustment(4, 0, 9, 1, 1, 0);
		spinAudioQuality = new Gtk.SpinButton (adjAudioQuality, 1, 0);
		spinAudioQuality.xalign = (float) 0.5;
		gridAudio.attach(spinAudioQuality,1,row,1,1);

		//lblOpusOptimize
		lblOpusOptimize = new Gtk.Label(_("Optimization"));
		lblOpusOptimize.xalign = (float) 0.0;
		lblOpusOptimize.no_show_all = true;
		gridAudio.attach(lblOpusOptimize,0,++row,1,1);

		//cmbOpusOptimize
		cmbOpusOptimize = new ComboBox();
		textCell = new CellRendererText();
        cmbOpusOptimize.pack_start(textCell, false);
        cmbOpusOptimize.set_attributes(textCell, "text", 0);
        cmbOpusOptimize.no_show_all = true;
        cmbOpusOptimize.set_size_request(150,-1);
        gridAudio.attach(cmbOpusOptimize,1,row,1,1);

        //populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("None"),1,"none");
		model.append (out iter);
		model.set (iter,0,_("Speech"),1,"speech");
		model.append (out iter);
		model.set (iter,0,_("Music"),1,"music");
		cmbOpusOptimize.set_model(model);

		//lblAacProfile
		lblAacProfile = new Gtk.Label(_("Profile"));
		lblAacProfile.xalign = (float) 0.0;
		lblAacProfile.no_show_all = true;
		gridAudio.attach(lblAacProfile,0,++row,1,1);

		//cmbAacProfile
		cmbAacProfile = new ComboBox();
		textCell = new CellRendererText();
        cmbAacProfile.pack_start(textCell, false);
        cmbAacProfile.set_attributes(textCell, "text", 0);
        cmbAacProfile.no_show_all = true;
        cmbAacProfile.set_size_request(150,-1);
        gridAudio.attach(cmbAacProfile,1,row,1,1);

		//tooltip
		string tt = _("<b>AAC-LC (Recommended)</b>\nMPEG-2 Low-complexity (LC) combined with MPEG-4 Perceptual Noise Substitution (PNS)\n\n");
		tt += _("<b>HE-AAC</b>\nAAC-LC + SBR (Spectral Band Replication)\n\n");
		tt += _("<b>HE-AAC v2</b>\nAAC-LC + SBR + PS (Parametric Stereo)\n\n");
		tt += _("<b>AAC-LD</b>\nLow Delay Profile for real-time communication\n\n");
		tt += _("<b>AAC-ELD</b>\nEnhanced Low Delay Profile for real-time communication\n\n");
		tt += _("<b>AAC-ELD</b>\nEnhanced Low Delay Profile for real-time communication\n\n");
		tt += _("<b>Note:</b>\nHE-AAC and HE-AACv2 are used for low-bitrate encoding while HE-LD and HE-ELD are used for real-time communication. HE-AAC is suitable for bit rates between 48 to 64 kbps (stereo) while HE-AACv2 is suitable for bit rates as low as 32 kbps.");
		cmbAacProfile.set_tooltip_markup(tt);
		lblAacProfile.set_tooltip_markup(tt);
		
        //populate
		cmbAacProfile_refresh();
		
		//imgAudioCodec
		imgAudioCodec = new Gtk.Image();
		imgAudioCodec.margin_top = 6;
		imgAudioCodec.margin_bottom = 6;
		imgAudioCodec.expand = true;
        gridAudio.attach(imgAudioCodec,0,++row,3,1);
	}

	private void init_ui_audio_filters(){
		//lblAudioFilters
		lblAudioFilters = new Label (_("Filters"));

        //gridAudioFilters
        gridAudioFilters = new Grid();
        gridAudioFilters.set_column_spacing (6);
        gridAudioFilters.set_row_spacing (6);
        gridAudioFilters.margin = 12;
        gridAudioFilters.visible = false;
        tabMain.append_page (gridAudioFilters, lblAudioFilters);

		int row = -1;
		//string tt = "";
		//Gtk.ListStore model;
		//TreeIter iter;
		int col;

		//lblHeaderSampling
		Label lblHeaderSampling = new Gtk.Label(_("<b>Channels &amp; Sampling:</b>"));
		lblHeaderSampling.set_use_markup(true);
		lblHeaderSampling.xalign = (float) 0.0;
		gridAudioFilters.attach(lblHeaderSampling,col=0,++row,2,1);

		//lblAudioSampleRate
		lblAudioSampleRate = new Gtk.Label(_("Sampling Rate (Hz)"));
		lblAudioSampleRate.xalign = (float) 0.0;
		gridAudioFilters.attach(lblAudioSampleRate,col=0,++row,1,1);

		//cmbAudioSampleRate
		cmbAudioSampleRate = new ComboBox();
		var textCell = new CellRendererText();
        cmbAudioSampleRate.pack_start(textCell, false);
        cmbAudioSampleRate.set_attributes(textCell, "text", 0);
        cmbAudioSampleRate.hexpand = true;
        gridAudioFilters.attach(cmbAudioSampleRate,col+1,row,1,1);

		//lblAudioChannels
		lblAudioChannels = new Gtk.Label(_("Channels"));
		lblAudioChannels.xalign = (float) 0.0;
		gridAudioFilters.attach(lblAudioChannels,col=0,++row,1,1);

		//cmbAudioChannels
		cmbAudioChannels = new ComboBox();
		textCell = new CellRendererText();
        cmbAudioChannels.pack_start(textCell, false);
        cmbAudioChannels.set_attributes(textCell, "text", 0);
        gridAudioFilters.attach(cmbAudioChannels,col+1,row,1,1);
	}

	private void init_ui_sox(){
		//int row = -1;
		string tt = "";
		Gtk.ListStore model;
		TreeIter iter;
		//int col;
		
		int scaleWidth = 200;
		int sliderMarginBottom = 0;
		int spacing = 5;

		//lblAudioFilters
		Label lblAudioSox = new Label ("" + _("SOX") + "");

        //vboxSox
        vboxSoxOuter = new Box(Orientation.VERTICAL,spacing);
		vboxSoxOuter.margin = 12;
        tabMain.append_page (vboxSoxOuter, lblAudioSox);

		//hboxSoxSwitch
		Box hboxSoxSwitch = new Box(Orientation.HORIZONTAL,0);
		hboxSoxSwitch.margin_bottom = 6;
        vboxSoxOuter.add(hboxSoxSwitch);

		//lblHeaderSox
		lblHeaderSox = new Gtk.Label(_("<b>SOX Audio Processing:</b>"));
		lblHeaderSox.set_use_markup(true);
		lblHeaderSox.xalign = (float) 0.0;
		lblHeaderSox.hexpand = true;
		hboxSoxSwitch.add(lblHeaderSox);

		//switchSox
        switchSox = new Gtk.Switch();
        switchSox.set_size_request(100,-1);
        hboxSoxSwitch.add(switchSox);

        //vboxSox
        Box vboxSox = new Box(Orientation.VERTICAL,spacing);
        vboxSoxOuter.add(vboxSox);

        switchSox.notify["active"].connect(()=>{
			vboxSox.sensitive = switchSox.active;

			App.Encoders["sox"].CheckAvailability();
			if (!App.Encoders["sox"].IsAvailable){
				if (switchSox.active){
					gtk_messagebox(_("Sox Not Installed"), _("The Sox utility was not found on your system") + "\n" + _("Please install the 'sox' package on your system to use this feature"), this, true);
					switchSox.active = false;
				}
			}
		});

		switchSox.active = false;
		vboxSox.sensitive = switchSox.active;

		//lblHeaderAdjustments
		Label lblHeaderAdjustments = new Gtk.Label(_("<b>Adjustments:</b>"));
		lblHeaderAdjustments.set_use_markup(true);
		lblHeaderAdjustments.xalign = (float) 0.0;
		lblHeaderAdjustments.hexpand = true;
		//lblHeaderAdjustments.margin_top = 5;
		lblHeaderAdjustments.margin_bottom = 5;
		vboxSox.add(lblHeaderAdjustments);

		//hboxBass
		Box hboxBass = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hboxBass);

		tt = _("Boost or cut the bass (lower) frequencies of the audio.");

		lblAudioBass = new Gtk.Label(_("Bass (lower freq)") + ": ");
		lblAudioBass.xalign = (float) 0.0;
		lblAudioBass.set_tooltip_text(tt);
		hboxBass.pack_start(lblAudioBass,false,false,0);

		scaleBass = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -20, 20, 1);
		scaleBass.adjustment.value = 0;
		scaleBass.has_origin = false;
		scaleBass.value_pos = PositionType.LEFT;
		scaleBass.set_size_request(scaleWidth,-1);
		scaleBass.margin_bottom = sliderMarginBottom;
		hboxBass.pack_start(scaleBass,true,true,0);

		scaleBass.format_value.connect((val)=>{ return "%.0f ".printf(val); });

		Button btnReset = new Button.with_label("X");
		btnReset.clicked.connect(()=>{ scaleBass.adjustment.value = 0; });
		btnReset.set_tooltip_text(_("Reset"));
        hboxBass.pack_start(btnReset,false,true,0);

		//hboxTreble
		Box hboxTreble = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hboxTreble);

		tt = _("Boost or cut the treble (upper) frequencies of the audio.");

		lblAudioTreble = new Gtk.Label(_("Treble (upper freq)") + ": ");
		lblAudioTreble.xalign = (float) 0.0;
		lblAudioTreble.set_tooltip_text(tt);
		hboxTreble.pack_start(lblAudioTreble,false,false,0);

		scaleTreble = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -20, 20, 1);
		scaleTreble.adjustment.value = 0;
		scaleTreble.has_origin = false;
		scaleTreble.value_pos = PositionType.LEFT;
		scaleTreble.set_size_request(scaleWidth,-1);
		scaleTreble.margin_bottom = sliderMarginBottom;
		hboxTreble.pack_start(scaleTreble,true,true,0);

		scaleTreble.format_value.connect((val)=>{ return "%.0f ".printf(val); });

		btnReset = new Button.with_label("X");
		btnReset.clicked.connect(()=>{ scaleTreble.adjustment.value = 0; });
		btnReset.set_tooltip_text(_("Reset"));
        hboxTreble.pack_start(btnReset,false,true,0);

		//hboxPitch
		Box hboxPitch = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hboxPitch);

		tt = _("Change audio pitch (shrillness) without changing audio tempo (speed).");

		lblAudioPitch = new Gtk.Label(_("Pitch (shrillness)") + ": ");
		lblAudioPitch.xalign = (float) 0.0;
		lblAudioPitch.set_tooltip_text(tt);
		hboxPitch.pack_start(lblAudioPitch,false,false,0);

		scalePitch = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 500, 1);
		scalePitch.adjustment.value = 100;
		//scalePitch.has_origin = false;
		scalePitch.value_pos = PositionType.LEFT;
		scalePitch.set_size_request(scaleWidth,-1);
		scalePitch.margin_bottom = sliderMarginBottom;
		hboxPitch.pack_start(scalePitch,true,true,0);

		scalePitch.format_value.connect((val)=>{ return "%.0f%% ".printf(val); });

		btnReset = new Button.with_label("X");
		btnReset.clicked.connect(()=>{ scalePitch.adjustment.value = 100; });
		btnReset.set_tooltip_text(_("Reset"));
        hboxPitch.pack_start(btnReset,false,true,0);

		//hboxTempo
		Box hboxTempo = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hboxTempo);

		tt = _("Change audio tempo (speed) without changing audio pitch (shrillness).\n\nWARNING: This will change the duration of the audio track");

		lblAudioTempo = new Gtk.Label(_("Tempo (speed)") + ": ");
		lblAudioTempo.xalign = (float) 0.0;
		lblAudioTempo.set_tooltip_text(tt);
		hboxTempo.pack_start(lblAudioTempo,false,false,0);

		scaleTempo = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 30, 200, 1);
		scaleTempo.adjustment.value = 100;
		//scaleTempo.has_origin = false;
		scaleTempo.value_pos = PositionType.LEFT;
		scaleTempo.set_size_request(scaleWidth,-1);
		scaleTempo.margin_bottom = sliderMarginBottom;
		hboxTempo.pack_start(scaleTempo,true,true,0);

		scaleTempo.format_value.connect((val)=>{ return "%.0f%% ".printf(val); });

		btnReset = new Button.with_label("X");
		btnReset.clicked.connect(()=>{ scaleTempo.adjustment.value = 100; });
		btnReset.set_tooltip_text(_("Reset"));
        hboxTempo.pack_start(btnReset,false,true,0);

		//lblHeaderFade
		Label lblHeaderFade = new Gtk.Label(_("<b>Fade:</b>"));
		lblHeaderFade.set_use_markup(true);
		lblHeaderFade.xalign = (float) 0.0;
		lblHeaderFade.hexpand = true;
		lblHeaderFade.margin_top = 5;
		lblHeaderFade.margin_bottom = 5;
		vboxSox.add(lblHeaderFade);

		//hboxFadeIn
		Box hboxFadeIn = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hboxFadeIn);

		lblFadeIn = new Gtk.Label(_("Fade In (seconds)"));
		lblFadeIn.xalign = (float) 0.0;
		lblFadeIn.set_size_request(150,-1);
		hboxFadeIn.pack_start(lblFadeIn,false,false,0);

		Gtk.Adjustment adjFadeIn = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spinFadeIn = new Gtk.SpinButton (adjFadeIn, 1, 0);
		spinFadeIn.xalign = (float) 0.5;
		hboxFadeIn.pack_start(spinFadeIn,false,false,0);

		//hboxFadeOut
		Box hboxFadeOut = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hboxFadeOut);

		lblFadeOut = new Gtk.Label(_("Fade Out (seconds)"));
		lblFadeOut.xalign = (float) 0.0;
		lblFadeOut.set_size_request(150,-1);
		hboxFadeOut.pack_start(lblFadeOut,false,false,0);

		Gtk.Adjustment adjFadeOut = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spinFadeOut = new Gtk.SpinButton (adjFadeOut, 1, 0);
		spinFadeOut.xalign = (float) 0.5;
		hboxFadeOut.pack_start(spinFadeOut,false,false,0);

		//hboxFadeType
		Box hboxFadeType = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hboxFadeType);

		Label lblFadeType = new Gtk.Label(_("Fade Type"));
		lblFadeType.xalign = (float) 0.0;
		lblFadeType.set_size_request(150,-1);
		hboxFadeType.pack_start(lblFadeType,false,false,0);

		cmbFadeType = new ComboBox();
		var textCell = new CellRendererText();
        cmbFadeType.pack_start(textCell, false);
        cmbFadeType.set_attributes(textCell, "text", 0);
		hboxFadeType.pack_start(cmbFadeType,false,false,0);

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("Quarter Sine"),1,"q");
		model.append (out iter);
		model.set (iter,0,_("Half Sine"),1,"h");
		model.append (out iter);
		model.set (iter,0,_("Linear"),1,"t");
		model.append (out iter);
		model.set (iter,0,_("Logarithmic"),1,"l");
		model.append (out iter);
		model.set (iter,0,_("Inverted Parabola"),1,"p");
		cmbFadeType.set_model(model);

		//lblHeaderOther
		Label lblHeaderOther = new Gtk.Label(_("<b>Other Effects:</b>"));
		lblHeaderOther.set_use_markup(true);
		lblHeaderOther.xalign = (float) 0.0;
		lblHeaderOther.hexpand = true;
		lblHeaderOther.margin_top = 5;
		lblHeaderOther.margin_bottom = 5;
		vboxSox.add(lblHeaderOther);

		//hboxNormalize
		Box hboxNormalize = new Box(Orientation.HORIZONTAL,0);
        vboxSox.add(hboxNormalize);

		tt = _("Maximize the volume level (loudness)");

		lblNormalize = new Gtk.Label(_("Maximize Volume Level (Normalize)"));
		lblNormalize.xalign = (float) 0.0;
		lblNormalize.hexpand = true;
		lblNormalize.set_tooltip_text(tt);
		hboxNormalize.pack_start(lblNormalize,true,true,0);

        switchNormalize = new Gtk.Switch();
        switchNormalize.set_size_request(100,-1);
        switchNormalize.active = false;
        hboxNormalize.pack_end(switchNormalize,false,false,0);

		//hboxEarWax
		Box hboxEarWax = new Box(Orientation.HORIZONTAL,0);
        vboxSox.add(hboxEarWax);

		tt = _("Makes audio easier to listen to on headphones. Adds 'cues' to the audio so that when listened to on headphones the stereo image is moved from inside your head (standard for headphones) to outside and in front of the listener (standard for speakers).");

		lblEarWax = new Gtk.Label(_("Adjust Stereo for Headphones"));
		lblEarWax.xalign = (float) 0.0;
		lblEarWax.hexpand = true;
		lblEarWax.set_tooltip_text(tt);
		hboxEarWax.pack_start(lblEarWax,true,true,0);

        switchEarWax = new Gtk.Switch();
        switchEarWax.set_size_request(100,-1);
        switchEarWax.active = false;
        hboxEarWax.pack_end(switchEarWax,false,false,0);

		//lnkSoxHome
		LinkButton lnkSoxHome = new LinkButton.with_label ("http://sox.sourceforge.net/", "SOund eXchange - http://sox.sourceforge.net/");
		lnkSoxHome.xalign = (float) 0.0;
		lnkSoxHome.valign = Align.END;
		lnkSoxHome.activate_link.connect(()=>{ return exo_open_url(lnkSoxHome.uri); });
        vboxSoxOuter.pack_end(lnkSoxHome,true,true,0);

	}
	
	private void init_ui_video(){
		//lblVideo
		lblVideo = new Label(_("Video"));

        //gridVideo
        gridVideo = new Grid();
        gridVideo.set_column_spacing (6);
        gridVideo.set_row_spacing (6);
        gridVideo.visible = false;
        gridVideo.margin = 12;
        tabMain.append_page (gridVideo, lblVideo);

		int row = -1;
		string tt = "";
		Gtk.ListStore model;
		TreeIter iter;
		
		//lblVCodec
		lblVCodec = new Gtk.Label(_("Format / Codec"));
		lblVCodec.xalign = (float) 0.0;
		gridVideo.attach(lblVCodec,0,++row,1,1);

		//cmbVCodec
		cmbVCodec = new ComboBox();
		var textCell = new CellRendererText();
        cmbVCodec.pack_start( textCell, false );
        cmbVCodec.set_attributes( textCell, "text", 0 );
        cmbVCodec.changed.connect(cmbVCodec_changed);
        cmbVCodec.hexpand = true;
        gridVideo.attach(cmbVCodec,1,row,1,1);

		cmbVCodec.notify["visible"].connect(()=>{
			lblVCodec.visible = cmbVCodec.visible;
		});

		//lblVCodecMessage
		lblVCodecMessage = new Gtk.Label("");
		lblVCodecMessage.xalign = (float) 0.0;
		lblVCodecMessage.no_show_all = true;
		lblVCodecMessage.wrap = true;
		lblVCodecMessage.wrap_mode = Pango.WrapMode.WORD;
		lblVCodecMessage.use_markup = true;
		gridVideo.attach(lblVCodecMessage,0,++row,2,1);
		
        //lblVideoMode
		lblVideoMode = new Gtk.Label(_("Encoding Mode"));
		lblVideoMode.xalign = (float) 0.0;
		gridVideo.attach(lblVideoMode,0,++row,1,1);

		//cmbVideoMode
		cmbVideoMode = new ComboBox();
		textCell = new CellRendererText();
        cmbVideoMode.pack_start( textCell, false );
        cmbVideoMode.set_attributes( textCell, "text", 0 );
        cmbVideoMode.changed.connect(cmbVideoMode_changed);
        gridVideo.attach(cmbVideoMode,1,row,1,1);

		cmbVideoMode.notify["visible"].connect(()=>{
			lblVideoMode.visible = cmbVideoMode.visible;
		});
		
        //lblVideoBitrate
		lblVideoBitrate = new Gtk.Label(_("Bitrate (kbps)"));
		lblVideoBitrate.xalign = (float) 0.0;
		lblVideoBitrate.set_tooltip_text ("");
		gridVideo.attach(lblVideoBitrate,0,++row,1,1);

		//spinVideoBitrate
		Gtk.Adjustment adjVideoBitrate = new Gtk.Adjustment(22.0, 0.0, 51.0, 0.1, 1.0, 0.0);
		spinVideoBitrate = new Gtk.SpinButton (adjVideoBitrate, 0.1, 2);
		spinVideoBitrate.xalign = (float) 0.5;
		gridVideo.attach(spinVideoBitrate,1,row,1,1);

		spinVideoBitrate.notify["visible"].connect(()=>{
			lblVideoBitrate.visible = spinVideoBitrate.visible;
		});
		
		tt = _("<b>Compression Vs Quality</b>\nSmaller values give better quality video and larger files");

        //lblVideoQuality
		lblVideoQuality = new Gtk.Label(_("Quality"));
		lblVideoQuality.xalign = (float) 0.0;
		lblVideoQuality.set_tooltip_markup(tt);
		gridVideo.attach(lblVideoQuality,0,++row,1,1);

		//spinVideoQuality
		Gtk.Adjustment adjVideoQuality = new Gtk.Adjustment(22.0, 0.0, 51.0, 0.1, 1.0, 0.0);
		spinVideoQuality = new Gtk.SpinButton (adjVideoQuality, 0.1, 2);
		spinVideoQuality.set_tooltip_markup(tt);
		spinVideoQuality.xalign = (float) 0.5;
		gridVideo.attach(spinVideoQuality,1,row,1,1);

		spinVideoQuality.notify["visible"].connect(()=>{
			lblVideoQuality.visible = spinVideoQuality.visible;
		});
		
		tt = _("<b>Compression Vs Encoding Speed</b>\nSlower presets give better compression and smaller files\nbut take more time to encode.");

        //lblPreset
		lblX264Preset = new Gtk.Label(_("Preset"));
		lblX264Preset.xalign = (float) 0.0;
		lblX264Preset.set_tooltip_markup(tt);
		gridVideo.attach(lblX264Preset,0,++row,1,1);

		//cmbx264Preset
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("UltraFast"), 1, "ultrafast");
		model.append (out iter);
		model.set (iter, 0, _("SuperFast"), 1, "superfast");
		model.append (out iter);
		model.set (iter, 0, _("Fast"), 1, "fast");
		model.append (out iter);
		model.set (iter, 0, _("Medium"), 1, "medium");
		model.append (out iter);
		model.set (iter, 0, _("Slow"), 1, "slow");
		model.append (out iter);
		model.set (iter, 0, _("Slower"), 1, "slower");
		model.append (out iter);
		model.set (iter, 0, _("VerySlow"), 1, "veryslow");

		cmbX264Preset = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbX264Preset.pack_start( textCell, false );
        cmbX264Preset.set_attributes( textCell, "text", 0 );
        cmbX264Preset.set_tooltip_markup(tt);
        gridVideo.attach(cmbX264Preset,1,row,1,1);

		cmbX264Preset.notify["visible"].connect(()=>{
			lblX264Preset.visible = cmbX264Preset.visible;
		});
		
		tt = _("<b>Compression Vs Device Compatibility</b>\n'High' profile gives the best compression.\nChange this to 'Baseline' or 'Main' only if you are encoding\nfor a particular device (mobiles,PMPs,etc) which does not\nsupport the 'High' profile");

		//lblProfile
		lblX264Profile = new Gtk.Label(_("Profile"));
		lblX264Profile.xalign = (float) 0.0;
		lblX264Profile.set_tooltip_markup(tt);
		gridVideo.attach(lblX264Profile,0,++row,1,1);

		//cmbX264Profile
		cmbX264Profile = new ComboBox();
		textCell = new CellRendererText();
        cmbX264Profile.pack_start( textCell, false );
        cmbX264Profile.set_attributes( textCell, "text", 0 );
        cmbX264Profile.set_tooltip_markup(tt);
        gridVideo.attach(cmbX264Profile,1,row,1,1);

		cmbX264Profile.notify["visible"].connect(()=>{
			lblX264Profile.visible = cmbX264Profile.visible;
		});
		
		//lblVpxSpeed
		lblVpxSpeed = new Gtk.Label(_("Speed"));
		lblVpxSpeed.xalign = (float) 0.0;
		lblVpxSpeed.no_show_all = true;
		gridVideo.attach(lblVpxSpeed,0,++row,1,1);

		Box hboxVpxSpeed = new Box (Orientation.HORIZONTAL, 0);
		hboxVpxSpeed.homogeneous = false;
		gridVideo.attach(hboxVpxSpeed,1,row,1,1);

		//cmbVpxSpeed
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("Best"), 1, "best");
		model.append (out iter);
		model.set (iter, 0, _("Good"), 1, "good");
		model.append (out iter);
		model.set (iter, 0, _("Realtime"), 1, "realtime");
		cmbVpxSpeed = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbVpxSpeed.pack_start( textCell, false );
        cmbVpxSpeed.set_attributes( textCell, "text", 0 );
        hboxVpxSpeed.add(cmbVpxSpeed);

        cmbVpxSpeed.changed.connect(cmbVpxSpeed_changed);

		cmbVpxSpeed.notify["visible"].connect(()=>{
			lblVpxSpeed.visible = cmbVpxSpeed.visible;
		});
		
        Label lblSpacer = new Gtk.Label("    ");
        hboxVpxSpeed.add(lblSpacer);

		//scaleVpxSpeed
        scaleVpxSpeed = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 5, 1);
		scaleVpxSpeed.adjustment.value = 1;
		scaleVpxSpeed.has_origin = false;
		scaleVpxSpeed.value_pos = PositionType.LEFT;
		scaleVpxSpeed.hexpand = true;
        hboxVpxSpeed.add(scaleVpxSpeed);

		tt = _("<b>Additional Options</b>\nThese options will be passed to the encoder\non the command line. Please do not specify\nany options that are already provided by the GUI.");

		//lblVCodecOptions
		lblVCodecOptions = new Gtk.Label(_("Extra Options"));
		lblVCodecOptions.xalign = (float) 0.0;
		lblVCodecOptions.margin_top = 6;
		lblVCodecOptions.set_tooltip_markup(tt);
		gridVideo.attach(lblVCodecOptions,0,++row,1,1);

		//txtVCodecOptions
		txtVCodecOptions = new Gtk.TextView();
		TextBuffer buff = new TextBuffer(null);
		txtVCodecOptions.buffer = buff;
		txtVCodecOptions.editable = true;
		txtVCodecOptions.buffer.text = "";
		txtVCodecOptions.expand = true;
		//txtVCodecOptions.set_size_request(-1,100);
		txtVCodecOptions.set_tooltip_markup(tt);
		txtVCodecOptions.set_wrap_mode (Gtk.WrapMode.WORD);

		txtVCodecOptions.notify["visible"].connect(()=>{
			lblVCodecOptions.visible = txtVCodecOptions.visible;
		});
		
		Gtk.ScrolledWindow scrollWin = new Gtk.ScrolledWindow (null, null);
		scrollWin.set_shadow_type (ShadowType.ETCHED_IN);
		scrollWin.add (txtVCodecOptions);
		//scrollWin.set_size_request(-1,100);
		gridVideo.attach(scrollWin,0,++row,2,1);

		txtVCodecOptions.notify["visible"].connect(()=>{
			scrollWin.visible = txtVCodecOptions.visible;
		});
		
		//imgVideoCodec
		imgVideoCodec = new Gtk.Image();
		imgVideoCodec.margin_top = 6;
		imgVideoCodec.margin_bottom = 6;
        gridVideo.attach(imgVideoCodec,0,++row,2,1);
	}

	private void init_ui_video_filters(){
		//lblVideoFilters
		lblVideoFilters = new Label (_("Filters"));

        //gridVideoFilters
        gridVideoFilters = new Grid();
        gridVideoFilters.set_column_spacing (6);
        gridVideoFilters.set_row_spacing (6);
        gridVideoFilters.margin = 12;
        gridVideoFilters.visible = false;
        tabMain.append_page (gridVideoFilters, lblVideoFilters);

		int row = -1;
		string tt = "";
		Gtk.ListStore model;
		TreeIter iter;

		//lblHeaderFrameSize
		lblHeaderFrameSize = new Gtk.Label(_("<b>Resize:</b>"));
		lblHeaderFrameSize.set_use_markup(true);
		lblHeaderFrameSize.xalign = (float) 0.0;
		lblHeaderFrameSize.margin_bottom = 6;
		gridVideoFilters.attach(lblHeaderFrameSize,0,++row,1,1);

		//lblFrameSize
		lblFrameSize = new Gtk.Label(_("Resolution"));
		lblFrameSize.xalign = (float) 0.0;
		gridVideoFilters.attach(lblFrameSize,0,++row,1,1);

		//cmbFrameSize
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("No Change"),1,"disable");
		model.append (out iter);
		model.set (iter,0,_("Custom"),1,"custom");
		model.append (out iter);
		model.set (iter,0,"320p",1,"320p");
		model.append (out iter);
		model.set (iter,0,"480p",1,"480p");
		model.append (out iter);
		model.set (iter,0,"720p",1,"720p");
		model.append (out iter);
		model.set (iter,0,"1080p",1,"1080p");

		cmbFrameSize = new ComboBox.with_model(model);
		var textCell = new CellRendererText();
        cmbFrameSize.pack_start( textCell, false );
        cmbFrameSize.set_attributes( textCell, "text", 0 );
        cmbFrameSize.changed.connect(cmbFrameSize_changed);
        cmbFrameSize.hexpand = true;
        gridVideoFilters.attach(cmbFrameSize,1,row,1,1);

		tt = _("Set either Width or Height and leave the other as 0.\nIt will be calculated automatically.\n\nSetting both width and height is not recommended\nsince the video may get stretched or squeezed.\n\nEnable the 'Fit-To-Box' option to avoid changes to aspect ratio.");

        //lblFrameSizeCustom
		lblFrameSizeCustom = new Gtk.Label(_("Width x Height"));
		lblFrameSizeCustom.xalign = (float) 0.0;
		lblFrameSizeCustom.no_show_all = true;
		lblFrameSizeCustom.set_tooltip_markup (tt);
		gridVideoFilters.attach(lblFrameSizeCustom,0,++row,1,1);

        //hboxFrameSize
        hboxFrameSize = new Box (Orientation.HORIZONTAL, 0);
		hboxFrameSize.homogeneous = false;
        gridVideoFilters.attach(hboxFrameSize,1,row,1,1);

        //spinWidth
		Gtk.Adjustment adjWidth = new Gtk.Adjustment(0, 0, 999999, 1, 16, 0);
		spinFrameWidth = new Gtk.SpinButton (adjWidth, 1, 0);
		spinFrameWidth.xalign = (float) 0.5;
		spinFrameWidth.no_show_all = true;
		spinFrameWidth.width_chars = 5;
		spinFrameWidth.set_tooltip_text (_("Width"));
		hboxFrameSize.pack_start (spinFrameWidth, false, false, 0);

		//spinHeight
		Gtk.Adjustment adjHeight = new Gtk.Adjustment(480, 0, 999999, 1, 16, 0);
		spinFrameHeight = new Gtk.SpinButton (adjHeight, 1, 0);
		spinFrameHeight.xalign = (float) 0.5;
		spinFrameHeight.no_show_all = true;
		spinFrameHeight.width_chars = 5;
		spinFrameHeight.set_tooltip_text (_("Height"));
		hboxFrameSize.pack_start (spinFrameHeight, false, false, 5);

		tt = _("The resizing filter affects the sharpness and compressibility of the video.\nFor example, the 'Lanzos' filter gives sharper video but the extra detail\nmakes the video more difficult to compress resulting in slightly bigger files.\nThe 'Bilinear' filter gives smoother video (less detail) and smaller files.");

		//lblResizingMethod
		lblResizingMethod = new Gtk.Label(_("Resizing Method"));
		lblResizingMethod.xalign = (float) 0.0;
		lblResizingMethod.set_tooltip_markup(tt);
		gridVideoFilters.attach(lblResizingMethod,0,++row,1,1);

		//cmbResizingMethod
		cmbResizingMethod = new ComboBox();
		textCell = new CellRendererText();
        cmbResizingMethod.pack_start(textCell, false);
        cmbResizingMethod.set_attributes(textCell, "text", 0);
        cmbResizingMethod.changed.connect(cmbAudioMode_changed);
        cmbResizingMethod.no_show_all = true;
        cmbResizingMethod.set_tooltip_markup(tt);
        gridVideoFilters.attach(cmbResizingMethod,1,row,1,1);

		tt = _("Fits the video in a box of given width and height.");

		//chkFitToBox
		chkFitToBox = new CheckButton.with_label(_("Do not stretch or squeeze the video (Fit-To-Box)"));
		chkFitToBox.active = true;
		chkFitToBox.set_tooltip_markup(tt);
		gridVideoFilters.attach(chkFitToBox,0,++row,2,1);

		tt = _("Video will not be resized if it's smaller than the given width and height");

		//chkNoUpScale
		chkNoUpScale = new CheckButton.with_label(_("No Up-Scaling"));
		chkNoUpScale.active = true;
		chkNoUpScale.set_tooltip_markup(tt);
		gridVideoFilters.attach(chkNoUpScale,0,++row,2,1);

		//lblHeaderFrameRate
		lblHeaderFrameRate = new Gtk.Label(_("<b>Resample:</b>"));
		lblHeaderFrameRate.set_use_markup(true);
		lblHeaderFrameRate.xalign = (float) 0.0;
		lblHeaderFrameRate.margin_top = 6;
		lblHeaderFrameRate.margin_bottom = 6;
		gridVideoFilters.attach(lblHeaderFrameRate,0,++row,1,1);

		//lblFPS
		lblFPS = new Gtk.Label(_("Frame Rate"));
		lblFPS.xalign = (float) 0.0;
		lblFPS.set_tooltip_text (_("Frames/sec"));
		gridVideoFilters.attach(lblFPS,0,++row,1,1);

		//cmbFPS
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("No Change"),1,"disable");
		model.append (out iter);
		model.set (iter,0,_("Custom"),1,"custom");
		model.append (out iter);
		model.set (iter,0,"25",1,"25");
		model.append (out iter);
		model.set (iter,0,"29.97",1,"29.97");
		model.append (out iter);
		model.set (iter,0,"30",1,"30");
		model.append (out iter);
		model.set (iter,0,"60",1,"60");

		cmbFPS = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbFPS.pack_start( textCell, false );
        cmbFPS.set_attributes( textCell, "text", 0 );
        cmbFPS.changed.connect(cmbFPS_changed);
        gridVideoFilters.attach(cmbFPS,1,row,1,1);

		//lblFPSCustom
		lblFPSCustom = new Gtk.Label(_("FPS Ratio"));
		lblFPSCustom.xalign = (float) 0.0;
		lblFPSCustom.no_show_all = true;
		tt = "<b>" + _("Examples:") + "</b>\n0 / 0  => " + _("No Change") + "\n25 / 1 => 25 fps\n30 / 1 => 30 fps\n30000 / 1001 => 29.97 fps";
		lblFPSCustom.set_tooltip_markup (tt);
		gridVideoFilters.attach(lblFPSCustom,0,++row,1,1);

        //hboxFrameRate
        hboxFPS = new Box (Orientation.HORIZONTAL, 0);
		hboxFPS.homogeneous = false;
        gridVideoFilters.attach(hboxFPS,1,row,1,1);

        //spinFPSNum
		Gtk.Adjustment adjFPSNum = new Gtk.Adjustment(0, 0, 999999, 1, 1, 0);
		spinFPSNum = new Gtk.SpinButton (adjFPSNum, 1, 0);
		spinFPSNum.xalign = (float) 0.5;
		spinFPSNum.no_show_all = true;
		spinFPSNum.width_chars = 5;
		spinFPSNum.set_tooltip_text (_("Numerator"));
		hboxFPS.pack_start(spinFPSNum, false, false, 0);

		//spinFPSDenom
		Gtk.Adjustment adjFPSDenom = new Gtk.Adjustment(0, 0, 999999, 1, 1, 0);
		spinFPSDenom = new Gtk.SpinButton (adjFPSDenom, 1, 0);
		spinFPSDenom.xalign = (float) 0.5;
		spinFPSDenom.no_show_all = true;
		spinFPSDenom.width_chars = 5;
		spinFPSDenom.set_tooltip_text (_("Denominator"));
		hboxFPS.pack_start(spinFPSDenom, false, false, 5);
	}

	private void init_ui_subtitles(){
		int row = 0;
        //Gtk.ListStore model;
        Gtk.CellRendererText textCell;
        //Gtk.TreeIter iter;
        string tt;
        
		//lblSubtitle
		lblSubtitle = new Label ("" + _("Subs") + "");

        //gridSubtitle
        gridSubtitle = new Grid();
        gridSubtitle.set_column_spacing (6);
        gridSubtitle.set_row_spacing (6);
        gridSubtitle.margin = 12;
        gridSubtitle.visible = false;
        tabMain.append_page (gridSubtitle, lblSubtitle);

		row = -1;

		tt = _("<b>Embed</b> - Subtitle files will be combined with the output file.\nThese subtitles can be switched off since they are added as a separate track");
		tt += "\n\n";
		tt += _("<b>Render</b> - Subtitles are rendered/burned on the video.\nThese subtitles cannot be switched off since they become a part of the video");

		//lblSubtitleMode
		lblSubtitleMode = new Gtk.Label(_("Subtitle Mode"));
		lblSubtitleMode.xalign = (float) 0.0;
		lblSubtitleMode.set_tooltip_markup (tt);
		gridSubtitle.attach(lblSubtitleMode,0,++row,1,1);

		//cmbSubtitleMode
		cmbSubtitleMode = new ComboBox();
		textCell = new CellRendererText();
        cmbSubtitleMode.pack_start( textCell, false );
        cmbSubtitleMode.set_attributes( textCell, "text", 0 );
        cmbSubtitleMode.changed.connect(cmbSubtitleMode_changed);
        cmbSubtitleMode.hexpand = true;
        cmbSubtitleMode.set_tooltip_markup (tt);
        gridSubtitle.attach(cmbSubtitleMode,1,row,1,1);

        //lblSubFormatMessage
		lblSubFormatMessage = new Gtk.Label(_("Subtitles"));
		lblSubFormatMessage.xalign = (float) 0.0;
		lblSubFormatMessage.hexpand = true;
		lblSubFormatMessage.margin_top = 6;
		lblSubFormatMessage.margin_bottom = 6;
		lblSubFormatMessage.wrap = true;
		lblSubFormatMessage.wrap_mode = Pango.WrapMode.WORD;
		lblSubFormatMessage.use_markup = true;
		lblSubFormatMessage.set_use_markup(true);
		gridSubtitle.attach(lblSubFormatMessage,0,++row,2,1);
	}
	
	private bool on_delete_event(Gdk.EventAny event){
		this.delete_event.disconnect(on_delete_event); //disconnect this handler
		btnSave_clicked();
		return false;
	}

	private bool init_delayed() {
		/* any actions that need to run after window has been displayed */
		if (tmr_init > 0) {
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		//Defaults --------------------------------

		cmbFileFormat.set_active(0);
		//cmbAudioMode.set_active(0);
		//cmbVideoMode.set_active(0);
		//cmbSubtitleMode.set_active(0);
		cmbOpusOptimize.set_active(0);
		cmbX264Preset.set_active(3);
		//cmbX264Profile.set_active(2);
		cmbVpxSpeed.set_active (1);
		cmbFPS.set_active (0);
		cmbFrameSize.set_active (0);
		cmbFadeType.set_active (0);
		//cmbResizingMethod.set_active (2);
		//cmbFileExtension.set_active (0);

		if (!IsNew){
			load_script();
		}
		
		return false;
	}
	
	private void cmbFileFormat_changed(){
		Gtk.ListStore model;
		TreeIter iter;

		//populate file extensions ---------------------------

		model = new Gtk.ListStore(2, typeof(string), typeof(string));
		cmbFileExtension.set_model(model);

		switch (format) {
			case "mp4v":
				model.append(out iter);
				model.set(iter, 0, "MP4", 1, ".mp4");
				model.append(out iter);
				model.set(iter, 0, "M4V", 1, ".m4v");
				cmbFileExtension.set_active(0);
				break;
			case "mp4a":
				model.append(out iter);
				model.set(iter, 0, "MP4", 1, ".mp4");
				model.append(out iter);
				model.set(iter, 0, "M4A", 1, ".m4a");
				cmbFileExtension.set_active(0);
				break;
			case "ogv":
				model.append(out iter);
				model.set(iter, 0, "OGV", 1, ".ogv");
				model.append(out iter);
				model.set(iter, 0, "OGG", 1, ".ogg");
				cmbFileExtension.set_active(0);
				break;
			case "ogg":
				model.append(out iter);
				model.set(iter, 0, "OGG", 1, ".ogg");
				model.append(out iter);
				model.set(iter, 0, "OGA", 1, ".oga");
				cmbFileExtension.set_active(0);
				break;
			default:
				model.append(out iter);
				model.set(iter, 0, format.up(), 1, "." + format);
				cmbFileExtension.set_active(0);
				break;
		}

		//populate video codecs ---------------------------

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbVCodec.set_model(model);
		
		switch (format) {
			case "mkv":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"H.264 / MPEG-4 AVC (x264)",1,"x264");
				//model.append (out iter);
				//model.set (iter,0,"H.265 / MPEG-H HEVC (x265)",1,"x265"); //not yet supported
				cmbVCodec.set_active(1);
				break;
			case "mp4v":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"H.264 / MPEG-4 AVC (x264)",1,"x264");
				model.append (out iter);
				model.set (iter,0,"H.265 / MPEG-H HEVC (x265)",1,"x265");
				cmbVCodec.set_active(1);
				break;
			case "ogv":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"Theora",1,"theora");
				cmbVCodec.set_active(1);
				break;
			case "webm":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"VP8",1,"vp8");
				model.append (out iter);
				model.set (iter,0,"VP9",1,"vp9");
				cmbVCodec.set_active(1);
				break;
			default:
				model.append (out iter);
				model.set (iter,0,_("Disable Video"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				cmbVCodec.set_active(0);
				break;
		}

		switch (format) {
			case "mkv":
			case "mp4v":
			case "ogv":
			case "webm":
				gridVideo.sensitive = true;
				gridVideoFilters.sensitive = true;
				break;
			default:
				gridVideo.sensitive = false;
				gridVideoFilters.sensitive = false;
				break;
		}

		//populate audio codecs ---------------------------

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbACodec.set_model(model);

		switch (format) {
			case "mkv":
				model.append (out iter);
				model.set (iter,0,_("Disable Audio"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Copy Audio"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"MP3 / LAME",1,"mp3lame");
				model.append (out iter);
				model.set (iter,0,"AAC / Libav",1,"aac");
				model.append (out iter);
				model.set (iter,0,"AAC / Nero",1,"neroaac");
				model.append (out iter);
				model.set (iter,0,"AAC / Fraunhofer FDK",1,"libfdk_aac");
				cmbACodec.set_active(3);
				break;

			case "mp4v":
				model.append (out iter);
				model.set (iter,0,_("Disable Audio"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Copy Audio"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"AAC / Libav",1,"aac");
				model.append (out iter);
				model.set (iter,0,"AAC / Nero",1,"neroaac");
				model.append (out iter);
				model.set (iter,0,"AAC / Fraunhofer FDK",1,"libfdk_aac");
				cmbACodec.set_active(2);
				break;

			case "ogv":
			case "webm":
				model.append (out iter);
				model.set (iter,0,_("Disable Audio"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Copy Audio"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"Vorbis",1,"vorbis");
				cmbACodec.set_active(2);
				break;

			case "ogg":
				model.append (out iter);
				model.set (iter,0,"Vorbis",1,"vorbis");
				cmbACodec.set_active(0);
				break;

			case "mp3":
				model.append (out iter);
				model.set (iter,0,"MP3 / LAME",1,"mp3lame");
				cmbACodec.set_active(0);
				break;

			case "mp4a":
				model.append (out iter);
				model.set (iter,0,"AAC / Libav",1,"aac");
				model.append (out iter);
				model.set (iter,0,"AAC / Nero",1,"neroaac");
				model.append (out iter);
				model.set (iter,0,"AAC / Fraunhofer FDK",1,"libfdk_aac");
				cmbACodec.set_active(0);
				break;

			case "opus":
				model.append (out iter);
				model.set (iter,0,"Opus",1,"opus");
				cmbACodec.set_active(0);
				break;

			case "ac3":
				model.append (out iter);
				model.set (iter,0,"AC3 / Libav",1,"ac3");
				cmbACodec.set_active(0);
				break;

			case "flac":
				model.append (out iter);
				model.set (iter,0,"FLAC / Libav",1,"flac");
				cmbACodec.set_active(0);
				break;

			case "wav":
				//model.append (out iter);
				//model.set (iter,0,"PCM 8-bit Signed / Libav",1,"pcm_s8");
				model.append (out iter);
				model.set (iter,0,"PCM 8-bit Unsigned / Libav",1,"pcm_u8");
				model.append (out iter);
				model.set (iter,0,"PCM 16-bit Signed LE / Libav",1,"pcm_s16le");
				//model.append (out iter);
				//model.set (iter,0,"PCM 16-bit Signed BE / Libav",1,"pcm_s16be");
				model.append (out iter);
				model.set (iter,0,"PCM 16-bit Unsigned LE / Libav",1,"pcm_u16le");
				//model.append (out iter);
				//model.set (iter,0,"PCM 16-bit Unsigned BE / Libav",1,"pcm_u16be");
				model.append (out iter);
				model.set (iter,0,"PCM 24-bit Signed LE / Libav",1,"pcm_s24le");
				//model.append (out iter);
				//model.set (iter,0,"PCM 24-bit Signed BE / Libav",1,"pcm_s24be");
				model.append (out iter);
				model.set (iter,0,"PCM 24-bit Unsigned LE / Libav",1,"pcm_u24le");
				//model.append (out iter);
				//model.set (iter,0,"PCM 24-bit Unsigned BE / Libav",1,"pcm_u24be");
				model.append (out iter);
				model.set (iter,0,"PCM 32-bit Signed LE / Libav",1,"pcm_s32le");
				//model.append (out iter);
				//model.set (iter,0,"PCM 32-bit Signed BE / Libav",1,"pcm_s32be");
				model.append (out iter);
				model.set (iter,0,"PCM 32-bit Unsigned LE / Libav",1,"pcm_u32le");
				//model.append (out iter);
				//model.set (iter,0,"PCM 32-bit Unsigned BE / Libav",1,"pcm_u32be");
				cmbACodec.set_active(1);
				break;
		}

		//populate subtitle options

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbSubtitleMode.set_model(model);

		switch (format){
			case "mkv":
			case "mp4v":
			case "ogg":
			case "ogv":
				gridSubtitle.sensitive = true;

				model.append (out iter);
				model.set (iter,0,_("No Subtitles"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Embed / Soft Subs"),1,"embed");
				cmbSubtitleMode.set_active(1);
				break;

			default:
				gridSubtitle.sensitive = false;
				break;
		}

		//set logo

		switch (format){
			case "mkv":
				imgFileFormat.set_from_file(App.SharedImagesFolder + "/matroska.png");
				imgFileFormat.xalign = (float) 0.5;
				imgFileFormat.yalign = (float) 1.0;
				break;
			case "opus":
				imgFileFormat.set_from_file(App.SharedImagesFolder + "/opus.png");
				imgFileFormat.xalign = (float) 0.5;
				imgFileFormat.yalign = (float) 1.0;
				break;
			case "webm":
				imgFileFormat.set_from_file(App.SharedImagesFolder + "/webm.png");
				imgFileFormat.xalign = (float) 0.5;
				imgFileFormat.yalign = (float) 1.0;
				break;
			case "ogg":
				imgFileFormat.set_from_file(App.SharedImagesFolder + "/vorbis.png");
				imgFileFormat.xalign = (float) 0.5;
				imgFileFormat.yalign = (float) 1.0;
				break;
			case "ogv":
				imgFileFormat.set_from_file(App.SharedImagesFolder + "/theora.png");
				imgFileFormat.xalign = (float) 0.5;
				imgFileFormat.yalign = (float) 1.0;
				break;
			case "ac3":
			case "flac":
			case "wav":
				imgFileFormat.set_from_file(App.SharedImagesFolder + "/libav.png");
				imgFileFormat.xalign = (float) 0.5;
				imgFileFormat.yalign = (float) 1.0;
				break;
			/*case "mp3":
				imgFileFormat.set_from_file(App.SharedImagesFolder + "/lame.png");
				imgFileFormat.xalign = (float) 0.5;
				imgFileFormat.yalign = (float) 1.0;
				break;*/
			default:
				imgFileFormat.clear();
				break;
		}
	}

	private void cmbACodec_changed(){
		Gtk.ListStore model;
		TreeIter iter;

		lblAudioMode.visible = false;
		cmbAudioMode.visible = false;
		lblAudioBitrate.visible = false;
		spinAudioBitrate.visible = false;
		lblAudioQuality.visible = false;
		spinAudioQuality.visible = false;
		lblOpusOptimize.visible = false;
		cmbOpusOptimize.visible = false;
		lblAacProfile.visible = false;
		cmbAacProfile.visible = false;

		//show message
		switch (acodec){
			case "copy":
				lblACodecMessage.visible = true;
				lblACodecMessage.label = "\n<b>Note:</b>\n\n1. Audio track will be copied directly to the output file without changes.\n\n2. Format of the audio track must be compatible with the selected file format. For example, if the input file contains AAC audio and the selected file format is WEBM, then encoding will fail - since WEBM does not support AAC audio.\n\n3. Input file can be trimmed only in basic mode (single segment). Selecting multiple segments using advanced mode will not work.";
				break;
			default:
				lblACodecMessage.visible = false;
				break;
		}
		
		//show & hide options
		switch (acodec){
			case "opus":
				//All modes require bitrate as input
				lblAudioMode.visible = true;
				cmbAudioMode.visible = true;
				lblAudioBitrate.visible = true;
				spinAudioBitrate.visible = true;
				//lblAudioQuality.visible = true;
				//spinAudioQuality.visible = true;
				lblOpusOptimize.visible = true;
				cmbOpusOptimize.visible = true;
				break;
			case "pcm_s8":
			case "pcm_u8":
			case "pcm_s16le":
			case "pcm_s16be":
			case "pcm_u16le":
			case "pcm_u16be":
			case "pcm_s24le":
			case "pcm_s24be":
			case "pcm_u24le":
			case "pcm_u24be":
			case "pcm_s32le":
			case "pcm_s32be":
			case "pcm_u32le":
			case "pcm_u32be":
			case "flac":
				//show nothing
				break;
			case "ac3":
				lblAudioMode.visible = true;
				cmbAudioMode.visible = true;
				lblAudioBitrate.visible = true;
				spinAudioBitrate.visible = true;
				break;
			case "aac":
			case "neroaac":
			case "libfdk_aac":
				lblAudioMode.visible = true;
				cmbAudioMode.visible = true;
				lblAudioBitrate.visible = true;
				spinAudioBitrate.visible = true;
				lblAudioQuality.visible = true;
				spinAudioQuality.visible = true;
				lblAacProfile.visible = true;
				cmbAacProfile.visible = true;
				break;
			case "mp3lame":
			case "vorbis":
				lblAudioMode.visible = true;
				cmbAudioMode.visible = true;
				lblAudioBitrate.visible = true;
				spinAudioBitrate.visible = true;
				lblAudioQuality.visible = true;
				spinAudioQuality.visible = true;
				break;
		}

		//disable options when audio is disabled
		switch (acodec){
			case "disable":
			case "copy":
				gridAudioFilters.sensitive = false;
				vboxSoxOuter.sensitive = false;
				break;
			default:
				gridAudioFilters.sensitive = true;
				vboxSoxOuter.sensitive = true;
				break;
		}

		//populate encoding modes
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbAudioMode.set_model(model);
			
		switch (acodec){
			case "mp3lame":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Constant Bitrate"),1,"cbr");
				model.append (out iter);
				model.set (iter,0,_("Constant Bitrate (Strict)"),1,"cbr-strict");
				cmbAudioMode.set_active(0);

				spinAudioBitrate.adjustment.configure(128, 32, 320, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;

				spinAudioQuality.adjustment.configure(4, 0, 9, 1, 1, 0);
				spinAudioQuality.set_tooltip_text ("");
				spinAudioQuality.digits = 0;

				cmbAudioMode.sensitive = true;
				spinAudioBitrate.sensitive = true;
				spinAudioQuality.sensitive = true;
				cmbAudioMode_changed();
				break;

			case "aac":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				cmbAudioMode.set_active(0);

				spinAudioBitrate.adjustment.configure(96, 8, 400, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;

				spinAudioQuality.adjustment.configure(1.0, 0.0, 2.0, 0.1, 0.1, 0);
				spinAudioQuality.digits = 1;

				cmbAudioMode.sensitive = true;
				cmbAudioMode_changed();
				break;

			case "libfdk_aac":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				cmbAudioMode.set_active(0);

				spinAudioBitrate.adjustment.configure(96, 8, 400, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;

				spinAudioQuality.adjustment.configure(3, 1, 5, 1, 1, 0);
				spinAudioQuality.digits = 1;
				spinAudioQuality.set_tooltip_text (
"""
1 = ~20-32 kbps/channel
2 = ~32-40 kbps/channel
3 = ~48-56 kbps/channel
4 = ~64-72 kbps/channel
5 = ~96-112 kbps/channel
""");

				cmbAudioMode.sensitive = true;
				cmbAudioMode_changed();
				break;
				
			case "neroaac":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Constant Bitrate"),1,"cbr");
				cmbAudioMode.set_active(0);

				spinAudioBitrate.adjustment.configure(96, 8, 400, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;

				spinAudioQuality.adjustment.configure(0.5, 0.0, 1.0, 0.1, 0.1, 0);
				spinAudioQuality.set_tooltip_text (
"""0.05 = ~ 16 kbps
0.15 = ~ 33 kbps
0.25 = ~ 66 kbps
0.35 = ~100 kbps
0.45 = ~146 kbps
0.55 = ~192 kbps
0.65 = ~238 kbps
0.75 = ~285 kbps
0.85 = ~332 kbps
0.95 = ~381 kbps""");
				spinAudioQuality.digits = 1;

				cmbAudioMode.sensitive = true;
				cmbAudioMode_changed();
				break;

			case "opus":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Constant Bitrate"),1,"cbr");
				cmbAudioMode.set_active(0);

				spinAudioBitrate.adjustment.configure(128, 6, 512, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;

				cmbAudioMode.sensitive = true;
				cmbAudioMode_changed();
				break;

			case "vorbis":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				cmbAudioMode.set_active(0);

				spinAudioBitrate.adjustment.configure(128, 32, 500, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;

				spinAudioQuality.adjustment.configure(3, -2, 10, 1, 1, 0);
				spinAudioQuality.set_tooltip_text ("");
				spinAudioQuality.digits = 1;

				cmbAudioMode.sensitive = true;
				cmbAudioMode_changed();
				break;

			case "ac3":
				model.append (out iter);
				model.set (iter,0,_("Fixed Bitrate"),1,"cbr");
				cmbAudioMode.set_active(0);

				spinAudioBitrate.adjustment.configure(128, 1, 512, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;

				cmbAudioMode.sensitive = true;
				cmbAudioMode_changed();
				break;

			case "pcm_s8":
			case "pcm_u8":
			case "pcm_s16le":
			case "pcm_s16be":
			case "pcm_u16le":
			case "pcm_u16be":
			case "pcm_s24le":
			case "pcm_s24be":
			case "pcm_u24le":
			case "pcm_u24be":
			case "pcm_s32le":
			case "pcm_s32be":
			case "pcm_u32le":
			case "pcm_u32be":
			case "flac":
				model.append (out iter);
				model.set (iter,0,_("Lossless"),1,"lossless");
				cmbAudioMode.set_active(0);

				cmbAudioMode.sensitive = true;
				break;

			default: //disable
				cmbAudioMode.visible = false;
				spinAudioBitrate.visible = false;
				spinAudioQuality.visible = false;
				break;
		}

		//populate special settings
		cmbAacProfile_refresh();

		//populate sampling rates
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbAudioSampleRate.set_model(model);
		switch (acodec){
			case "mp3lame":
			case "opus":
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				model.append (out iter);
				model.set (iter,0,"8000",1,"8000");
				model.append (out iter);
				model.set (iter,0,"11025",1,"11025");
				model.append (out iter);
				model.set (iter,0,"12000",1,"12000");
				model.append (out iter);
				model.set (iter,0,"16000",1,"16000");
				model.append (out iter);
				model.set (iter,0,"22050",1,"22050");
				model.append (out iter);
				model.set (iter,0,"24000",1,"24000");
				model.append (out iter);
				model.set (iter,0,"32000",1,"32000");
				model.append (out iter);
				model.set (iter,0,"44100",1,"44100");
				model.append (out iter);
				model.set (iter,0,"48000",1,"48000");
				cmbAudioSampleRate.set_active(0);
				break;

			case "pcm_s8":
			case "pcm_u8":
			case "pcm_s16le":
			case "pcm_s16be":
			case "pcm_u16le":
			case "pcm_u16be":
			case "pcm_s24le":
			case "pcm_s24be":
			case "pcm_u24le":
			case "pcm_u24be":
			case "pcm_s32le":
			case "pcm_s32be":
			case "pcm_u32le":
			case "pcm_u32be":
			case "flac":
			case "aac":
			case "libfdk_aac":
			case "neroaac":
			case "vorbis":
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				model.append (out iter);
				model.set (iter,0,"8000",1,"8000");
				model.append (out iter);
				model.set (iter,0,"11025",1,"11025");
				model.append (out iter);
				model.set (iter,0,"12000",1,"12000");
				model.append (out iter);
				model.set (iter,0,"16000",1,"16000");
				model.append (out iter);
				model.set (iter,0,"22050",1,"22050");
				model.append (out iter);
				model.set (iter,0,"24000",1,"24000");
				model.append (out iter);
				model.set (iter,0,"32000",1,"32000");
				model.append (out iter);
				model.set (iter,0,"44100",1,"44100");
				model.append (out iter);
				model.set (iter,0,"48000",1,"48000");
				model.append (out iter);
				model.set (iter,0,"88200",1,"88200");
				model.append (out iter);
				model.set (iter,0,"96000",1,"96000");
				cmbAudioSampleRate.set_active(0);
				break;

			case "ac3":
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				model.append (out iter);
				model.set (iter,0,"24000",1,"24000");
				model.append (out iter);
				model.set (iter,0,"32000",1,"32000");
				model.append (out iter);
				model.set (iter,0,"44100",1,"44100");
				model.append (out iter);
				model.set (iter,0,"48000",1,"48000");
				cmbAudioSampleRate.set_active(0);
				break;

			default:
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				cmbAudioSampleRate.set_active(0);
				break;
		}

		//populate channels
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbAudioChannels.set_model(model);
		switch (acodec){
			case "ac3":
			case "flac":
			case "pcm_s8":
			case "pcm_u8":
			case "pcm_s16le":
			case "pcm_s16be":
			case "pcm_u16le":
			case "pcm_u16be":
			case "pcm_s24le":
			case "pcm_s24be":
			case "pcm_u24le":
			case "pcm_u24be":
			case "pcm_s32le":
			case "pcm_s32be":
			case "pcm_u32le":
			case "pcm_u32be":
			case "neroaac":
			case "aac":
			case "libfdk_aac":
			case "opus":
			case "vorbis":
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				model.append (out iter);
				model.set (iter,0,"1",1,"1");
				model.append (out iter);
				model.set (iter,0,"2",1,"2");
				model.append (out iter);
				model.set (iter,0,"3",1,"3");
				model.append (out iter);
				model.set (iter,0,"4",1,"4");
				model.append (out iter);
				model.set (iter,0,"5",1,"5");
				model.append (out iter);
				model.set (iter,0,"6",1,"6");
				model.append (out iter);
				model.set (iter,0,"7",1,"7");
				cmbAudioChannels.set_active(0);
				break;

			default: //mp3lame
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				model.append (out iter);
				model.set (iter,0,"1",1,"1");
				model.append (out iter);
				model.set (iter,0,"2",1,"2");
				cmbAudioChannels.set_active(0);
				break;
		}

		//set logo
		switch (acodec){
			case "opus":
				imgAudioCodec.set_from_file(App.SharedImagesFolder + "/opus.png");
				imgAudioCodec.xalign = (float) 0.5;
				imgAudioCodec.yalign = (float) 1.0;
				break;
			case "mp3lame":
				imgAudioCodec.set_from_file(App.SharedImagesFolder + "/lame.png");
				imgAudioCodec.xalign = (float) 0.5;
				imgAudioCodec.yalign = (float) 1.0;
				break;
			case "vorbis":
				imgAudioCodec.set_from_file(App.SharedImagesFolder + "/vorbis.png");
				imgAudioCodec.xalign = (float) 0.5;
				imgAudioCodec.yalign = (float) 1.0;
				break;
			case "ac3":
			case "flac":
			case "pcm_s8":
			case "pcm_u8":
			case "pcm_s16le":
			case "pcm_s16be":
			case "pcm_u16le":
			case "pcm_u16be":
			case "pcm_s24le":
			case "pcm_s24be":
			case "pcm_u24le":
			case "pcm_u24be":
			case "pcm_s32le":
			case "pcm_s32be":
			case "pcm_u32le":
			case "pcm_u32be":
				imgAudioCodec.set_from_file(App.SharedImagesFolder + "/libav.png");
				imgAudioCodec.xalign = (float) 0.5;
				imgAudioCodec.yalign = (float) 1.0;
				break;
			/*case "neroaac":
				imgAudioCodec.set_from_file(App.SharedImagesFolder + "/aac.png");
				imgAudioCodec.xalign = (float) 1.0;
				imgAudioCodec.yalign = (float) 1.0;
				break;*/
			default:
				imgAudioCodec.clear();
				break;
		}
	}

	private void cmbAudioMode_changed(){
		switch (audio_mode) {
			case "vbr":
				if (acodec == "opus") {
					spinAudioBitrate.sensitive = true;
					spinAudioQuality.sensitive = false;
				}
				else {
					spinAudioBitrate.sensitive = false;
					spinAudioQuality.sensitive = true;
				}
				break;
			case "abr":
			case "cbr":
			case "cbr-strict":
				spinAudioBitrate.sensitive = true;
				spinAudioQuality.sensitive = false;
				break;
		}
	}

	private void cmbVCodec_changed(){
		Gtk.ListStore model;
		TreeIter iter;

		//show message
		switch (vcodec){
			case "copy":
				lblVCodecMessage.visible = true;
				lblVCodecMessage.label = "\n<b>Note:</b>\n\n1. Video track will be copied directly to the output file without changes.\n\n2. Format of the video track must be compatible with the selected file format. For example, if the input file contains H264 video and the selected file format is WEBM, then encoding will fail - since WEBM does not support H264 video.\n\n3. Input file can be trimmed only in basic mode (single segment). Selecting multiple segments using advanced mode will not work.";
				break;
			default:
				lblVCodecMessage.visible = false;
				break;
		}

		//disable options when video is disabled
		switch (vcodec){
			case "disable":
			case "copy":
				gridVideoFilters.sensitive = false;
				break;
			default:
				gridVideoFilters.sensitive = true;
				break;
		}
		
		//show x264 options
		switch (vcodec){
			case "x264":
			case "x265":
				cmbX264Preset.visible = true;
				cmbX264Profile.visible = true;
				break;
			default:
				cmbX264Preset.visible = false;
				cmbX264Profile.visible = false;
				break;
		}

		switch(vcodec){
			case "x264":
				model = new Gtk.ListStore (2, typeof (string), typeof (string));
				model.append (out iter);
				model.set (iter, 0, "Baseline", 1, "baseline");
				model.append (out iter);
				model.set (iter, 0, "Main", 1, "main");
				model.append (out iter);
				model.set (iter, 0, "High", 1, "high");
				model.append (out iter);
				model.set (iter, 0, "High10", 1, "high10");
				model.append (out iter);
				model.set (iter, 0, "High422", 1, "high422");
				model.append (out iter);
				model.set (iter, 0, "High444", 1, "high444");
				cmbX264Profile.set_model(model);
				cmbX264Profile.set_active(2);
				break;

			case "x265":
				model = new Gtk.ListStore (2, typeof (string), typeof (string));
				model.append (out iter);
				model.set (iter, 0, "None", 1, "");
				model.append (out iter);
				model.set (iter, 0, "Main", 1, "main");
				model.append (out iter);
				model.set (iter, 0, "Main10", 1, "main10");
				cmbX264Profile.set_model(model);
				cmbX264Profile.set_active(0);
				break;
		}

		//show vp8 options
		switch (vcodec){
			case "vp8":
			case "vp9":
				cmbVpxSpeed.visible = true;
				scaleVpxSpeed.visible = true;
				scaleVpxSpeed.adjustment.value = 1;

				lblVpxSpeed.set_tooltip_markup("");
				string tt = _("<b>Quality Vs Encoding Speed</b>\n\n<b>Best:</b> Best quality, slower\n<b>Good:</b> Good quality, faster\n<b>Realtime:</b> Fastest");
				cmbVpxSpeed.set_tooltip_markup(tt);
				tt = _("<b>Quality Vs Encoding Speed</b>\n\nSmaller values = Better quality, slower\nLarger value = Lower quality, faster\n");
				scaleVpxSpeed.set_tooltip_markup(tt);
				break;

			default:
				cmbVpxSpeed.visible = false;
				scaleVpxSpeed.visible = false;

				string tt = _("<b>Quality Vs Encoding Speed</b>\nHigher values speed-up encoding at the expense of quality.\nLower values improve quality at the expense of encoding speed.");
				lblVpxSpeed.set_tooltip_markup(tt);
				break;
		}

		//populate encoding modes
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbVideoMode.set_model(model);

		switch (vcodec){
			case "x264":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate / CRF"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate (2-pass)"),1,"2pass");
				cmbVideoMode.set_active(0);

				spinVideoBitrate.adjustment.configure(800, 1, 10000000, 1, 1, 0);
				spinVideoBitrate.set_tooltip_text ("");
				spinVideoBitrate.digits = 0;

				spinVideoQuality.adjustment.configure(23.0, 0, 51, 1, 1, 0);
				spinVideoQuality.set_tooltip_text ("");
				spinVideoQuality.digits = 1;

				cmbVideoMode.visible = true;
				spinVideoBitrate.visible = true;
				spinVideoQuality.visible = true;
				txtVCodecOptions.visible = true;
				
				cmbVideoMode_changed();
				break;

			case "x265":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate / CRF"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate (2-pass)"),1,"2pass");
				cmbVideoMode.set_active(0);

				spinVideoBitrate.adjustment.configure(800, 1, 10000000, 1, 1, 0);
				spinVideoBitrate.set_tooltip_text ("");
				spinVideoBitrate.digits = 0;

				spinVideoQuality.adjustment.configure(28.0, 0, 51, 1, 1, 0);
				spinVideoQuality.set_tooltip_text ("");
				spinVideoQuality.digits = 1;

				cmbVideoMode.visible = true;
				spinVideoBitrate.visible = true;
				spinVideoQuality.visible = true;
				txtVCodecOptions.visible = true;
				
				cmbVideoMode_changed();
				break;

			case "theora":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate (2-pass)"),1,"2pass");
				cmbVideoMode.set_active(0);

				spinVideoBitrate.adjustment.configure(800, 1, 10000000, 1, 1, 0);
				spinVideoBitrate.set_tooltip_text ("");
				spinVideoBitrate.digits = 0;

				spinVideoQuality.adjustment.configure(6, 0, 10, 1, 1, 0);
				spinVideoQuality.set_tooltip_text ("");
				spinVideoQuality.digits = 1;

				cmbVideoMode.visible = true;
				spinVideoBitrate.visible = true;
				spinVideoQuality.visible = true;
				txtVCodecOptions.visible = true;
				cmbVideoMode_changed();
				break;

			case "vp8":
			case "vp9":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate (2pass)"),1,"2pass");
				model.append (out iter);
				model.set (iter,0,_("Constant Bitrate"),1,"cbr");
				//model.append (out iter);
				//model.set (iter,0,_("Constant Quality"),1,"cq");
				cmbVideoMode.set_active(0);

				spinVideoBitrate.adjustment.configure(800, 1, 1000000000, 1, 1, 0);
				spinVideoBitrate.set_tooltip_text ("");
				spinVideoBitrate.digits = 0;

				/*spinVideoQuality.adjustment.configure(-1, -1, 63, 1, 1, 0);
				spinVideoQuality.set_tooltip_text ("");
				spinVideoQuality.digits = 0;*/

				cmbVideoMode.visible = true;
				spinVideoBitrate.visible = true;
				spinVideoQuality.visible = false;
				txtVCodecOptions.visible = true;
				cmbVideoMode_changed();
				break;

			default: //disable
				cmbVideoMode.visible = false;
				spinVideoBitrate.visible = false;
				spinVideoQuality.visible = false;
				txtVCodecOptions.visible = false;
				break;
		}

		//populate resize methods
        model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbResizingMethod.set_model(model);

		switch (vcodec){
			case "x264":
			case "x265":
				lblResizingMethod.visible = true;
				cmbResizingMethod.visible = true;
				model.append (out iter);
				model.set (iter,0,"Fast Bilinear",1,"fastbilinear");
				model.append (out iter);
				model.set (iter,0,"Bilinear",1,"bilinear");
				model.append (out iter);
				model.set (iter,0,"Bicubic",1,"bicubic");
				model.append (out iter);
				model.set (iter,0,"Experimental",1,"experimental");
				model.append (out iter);
				model.set (iter,0,"Point",1,"point");
				model.append (out iter);
				model.set (iter,0,"Area",1,"area");
				model.append (out iter);
				model.set (iter,0,"Bicublin",1,"bicublin");
				model.append (out iter);
				model.set (iter,0,"Gaussian",1,"gauss");
				model.append (out iter);
				model.set (iter,0,"Sinc",1,"sinc");
				model.append (out iter);
				model.set (iter,0,"Lanczos",1,"lanczos");
				cmbResizingMethod.set_active(2);
				break;

			default:
				lblResizingMethod.visible = false;
				cmbResizingMethod.visible = false;
				break;

		}

		//set logo
		switch (vcodec){
			case "x264":
				imgVideoCodec.set_from_file(App.SharedImagesFolder + "/x264.png");
				imgVideoCodec.xalign = (float) 0.5;
				imgVideoCodec.yalign = (float) 1.0;
				break;
			case "x265":
				imgVideoCodec.set_from_file(App.SharedImagesFolder + "/x265.png");
				imgVideoCodec.xalign = (float) 0.5;
				imgVideoCodec.yalign = (float) 1.0;
				break;
			case "vp8":
				imgVideoCodec.set_from_file(App.SharedImagesFolder + "/vp8.png");
				imgVideoCodec.xalign = (float) 0.5;
				imgVideoCodec.yalign = (float) 1.0;
				break;
			case "vp9":
				imgVideoCodec.set_from_file(App.SharedImagesFolder + "/vp9.png");
				imgVideoCodec.xalign = (float) 0.5;
				imgVideoCodec.yalign = (float) 1.0;
				break;
			case "theora":
				imgVideoCodec.set_from_file(App.SharedImagesFolder + "/theora.png");
				imgVideoCodec.xalign = (float) 0.5;
				imgVideoCodec.yalign = (float) 1.0;
				break;
			default:
				imgVideoCodec.clear();
				break;
		}
	}

	private void cmbFrameSize_changed(){
		if (gtk_combobox_get_value(cmbFrameSize,1,"disable") == "custom") {
			spinFrameWidth.sensitive = true;
			spinFrameHeight.sensitive = true;
		}
		else{
			spinFrameWidth.sensitive = false;
			spinFrameHeight.sensitive = false;
		}

		if (gtk_combobox_get_value(cmbFrameSize,1,"disable") == "disable") {
			cmbResizingMethod.sensitive = false;
			chkFitToBox.sensitive = false;
			chkNoUpScale.sensitive = false;
		}
		else {
			cmbResizingMethod.sensitive = true;
			chkFitToBox.sensitive = true;
			chkNoUpScale.sensitive = true;
		}

		switch (gtk_combobox_get_value(cmbFrameSize,1,"disable")) {
			case "disable":
				spinFrameWidth.value = 0;
				spinFrameHeight.value = 0;
				break;
			case "custom":
				spinFrameWidth.value = 0;
				spinFrameHeight.value = 480;
				break;
			case "320p":
				spinFrameWidth.value = 0;
				spinFrameHeight.value = 320;
				break;
			case "480p":
				spinFrameWidth.value = 0;
				spinFrameHeight.value = 480;
				break;
			case "720p":
				spinFrameWidth.value = 0;
				spinFrameHeight.value = 720;
				break;
			case "1080p":
				spinFrameWidth.value = 0;
				spinFrameHeight.value = 1080;
				break;
		}

		lblFrameSizeCustom.visible = true;
		spinFrameWidth.visible = true;
		spinFrameHeight.visible = true;

		/*
		if (gtk_combobox_get_value(cmbFrameSize,1,"disable") == "disable"){
			lblFrameSizeCustom.visible = false;
			spinFrameWidth.visible = false;
			spinFrameHeight.visible = false;
		}
		else {
			lblFrameSizeCustom.visible = true;
			spinFrameWidth.visible = true;
			spinFrameHeight.visible = true;
		}*/
	}

	private void cmbFPS_changed(){
		if (gtk_combobox_get_value(cmbFPS,1,"disable") == "custom") {
			spinFPSNum.sensitive = true;
			spinFPSDenom.sensitive = true;
		}
		else{
			spinFPSNum.sensitive = false;
			spinFPSDenom.sensitive = false;
		}

		switch (gtk_combobox_get_value(cmbFPS,1,"disable")) {
			case "disable":
				spinFPSNum.value = 0;
				spinFPSDenom.value = 0;
				break;
			case "custom":
				spinFPSNum.value = 25;
				spinFPSDenom.value = 1;
				break;
			case "25":
				spinFPSNum.value = 25;
				spinFPSDenom.value = 1;
				break;
			case "29.97":
				spinFPSNum.value = 30000;
				spinFPSDenom.value = 1001;
				break;
			case "30":
				spinFPSNum.value = 30;
				spinFPSDenom.value = 1;
				break;
			case "60":
				spinFPSNum.value = 60;
				spinFPSDenom.value = 1;
				break;
		}

		lblFPSCustom.visible = true;
		spinFPSNum.visible = true;
		spinFPSDenom.visible = true;
		/*
		if (gtk_combobox_get_value(cmbFPS,1,"disable") == "disable"){
			lblFPSCustom.visible = false;
			spinFPSNum.visible = false;
			spinFPSDenom.visible = false;
		}
		else {
			lblFPSCustom.visible = true;
			spinFPSNum.visible = true;
			spinFPSDenom.visible = true;
		}*/
	}

	private void cmbVideoMode_changed(){
		switch(vcodec){
			case "vp8":
			case "vp9":
				switch (video_mode) {
					case "cq":
						spinVideoBitrate.sensitive = false;
						spinVideoQuality.sensitive = true;
						break;
					case "vbr":
					case "cbr":
					case "2pass":
						spinVideoBitrate.sensitive = true;
						spinVideoQuality.sensitive = false;
						break;
					default:
						spinVideoBitrate.sensitive = false;
						spinVideoQuality.sensitive = false;
						break;
				}
				break;
			default:
				switch (video_mode) {
					case "vbr":
						spinVideoBitrate.sensitive = false;
						spinVideoQuality.sensitive = true;
						break;
					case "abr":
					case "2pass":
						spinVideoBitrate.sensitive = true;
						spinVideoQuality.sensitive = false;
						break;
					default:
						spinVideoBitrate.sensitive = false;
						spinVideoQuality.sensitive = false;
						break;
				}
				break;
		}

	}

	private void cmbVpxSpeed_changed(){
		switch (vpx_deadline) {
			case "best":
				scaleVpxSpeed.adjustment.configure(0, 0, 0, 1, 1, 0);
				scaleVpxSpeed.sensitive = false;
				break;

			case "realtime":
				scaleVpxSpeed.sensitive = true;
				scaleVpxSpeed.adjustment.configure(0, 0, 15, 1, 1, 0);
				break;

			case "good":
			default:
				scaleVpxSpeed.sensitive = true;
				scaleVpxSpeed.adjustment.configure(1, 0, 5, 1, 1, 0);
				break;
		}
	}

	private void cmbSubtitleMode_changed(){
		string txt = "";
				
		switch(subtitle_mode){
			case "embed":
				txt += "\n<b>Note:</b>\n\n";
				txt += "1. Supported subtitle file formats";
				switch(format){
					case "mkv":
						txt += " - <i>SRT, SUB, SSA</i>";
						break;
					case "mp4v":
						txt += " - <i>SRT, SUB, TTXT, XML</i>";
						break;
					case "ogv":
						txt += " - <i>SRT</i>";
						break;
					case "ogg":
						txt += " - <i>SRT, LRC</i>";
						break;
					default:
						txt += " - None";
						break;
				}
				txt += "\n\n";

				txt += "2. Subtitle files must be present in the same location and start with the same file name.\n\n";

				txt += "3. If an external subtitle file is not found, then the first embedded track in the input file will be used.\n\n";
				break;

			default:
				txt = "";
				break;
		}

		lblSubFormatMessage.label = txt;
	}

	private void cmbAacProfile_refresh(){
		TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("Auto"),1,"auto");
		
		switch(acodec){
			case "neroaac":
				model.append (out iter);
				model.set (iter,0,_("AAC-LC"),1,"lc");
				model.append (out iter);
				model.set (iter,0,_("HE-AAC"),1,"he");
				model.append (out iter);
				model.set (iter,0,_("HE-AAC v2"),1,"hev2");
				break;
				
			case "aac":
				model.append (out iter);
				model.set (iter,0,_("AAC-LC"),1,"lc");
				model.append (out iter);
				model.set (iter,0,_("HE-AAC"),1,"he");
				model.append (out iter);
				model.set (iter,0,_("HE-AAC v2"),1,"hev2");
				model.append (out iter);
				model.set (iter,0,_("AAC-LD"),1,"ld");
				model.append (out iter);
				model.set (iter,0,_("AAC-ELD"),1,"eld");
				model.append (out iter);
				model.set (iter,0,_("MPEG-2 AAC-LC"),1,"mpeg2_lc");
				model.append (out iter);
				model.set (iter,0,_("MPEG-2 HE-AAC"),1,"mpeg2_he");
				//model.append (out iter);
				//model.set (iter,0,_("MPEG-2 HE-AAC v2"),1,"mpeg2_hev2");
				break;

			case "libfdk_aac":
				model.append (out iter);
				model.set (iter,0,_("AAC-LC"),1,"lc");
				model.append (out iter);
				model.set (iter,0,_("HE-AAC"),1,"he");
				model.append (out iter);
				model.set (iter,0,_("HE-AAC v2"),1,"hev2");
				model.append (out iter);
				model.set (iter,0,_("AAC-LD"),1,"ld");
				model.append (out iter);
				model.set (iter,0,_("AAC-ELD"),1,"eld");
				model.append (out iter);
				model.set (iter,0,_("MPEG-2 AAC-LC"),1,"mpeg2_lc");
				model.append (out iter);
				model.set (iter,0,_("MPEG-2 HE-AAC"),1,"mpeg2_he");
				model.append (out iter);
				model.set (iter,0,_("MPEG-2 HE-AAC v2"),1,"mpeg2_hev2");
				break;
		}

		cmbAacProfile.set_model(model);
		cmbAacProfile.active = 0;
	}
	
	private void btnSave_clicked(){

		if (txtPresetName.text.length < 1) {
			tabMain.page = 0;

			string msg = _("Please enter a name for this preset");
			var dlg = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, msg);
			dlg.set_title(_("Empty Preset Name"));
			dlg.set_modal(true);
			dlg.set_transient_for(this);
			dlg.run();
			dlg.destroy();

			return;
		}

		save_script();
		destroy();
	}

	private void save_script(){
		var config = new Json.Object();
		var general = new Json.Object();
		var video = new Json.Object();
		var audio = new Json.Object();
		var subs = new Json.Object();

		config.set_object_member("general",general);
		general.set_string_member("format",format);
		general.set_string_member("extension",extension);
		general.set_string_member("authorName",author_name);
		general.set_string_member("authorEmail",author_email);
		general.set_string_member("presetName",preset_name);
		general.set_string_member("presetVersion",preset_version);

		config.set_object_member("video",video);
		video.set_string_member("codec",vcodec);
		if (vcodec != "disable") {
			video.set_string_member("mode",video_mode);
			video.set_string_member("bitrate",video_bitrate);
			video.set_string_member("quality",video_quality);
			if ((vcodec == "x264")||(vcodec == "x265")){
				video.set_string_member("profile",x264_profile);
				video.set_string_member("preset",x264_preset);
			}
			if ((vcodec == "vp8")||(vcodec == "vp9")){
				video.set_string_member("vpx_deadline",vpx_deadline);
				video.set_string_member("vpx_speed",vpx_speed);
			}
			video.set_string_member("options",x264_options);
			video.set_string_member("frameSize",frame_size);
			video.set_string_member("frameWidth",frame_width);
			video.set_string_member("frameHeight",frame_height);
			video.set_string_member("resizingMethod",resizing_method);
			video.set_boolean_member("noUpscaling",no_upscaling);
			video.set_boolean_member("fitToBox",fit_to_box);
			video.set_string_member("fps",frame_rate);
			video.set_string_member("fpsNum",frame_rate_num);
			video.set_string_member("fpsDenom",frame_rate_denom);
		}

		config.set_object_member("audio",audio);
		audio.set_string_member("codec",acodec);
		if (acodec != "disable") {
			//codec
			audio.set_string_member("mode",audio_mode);
			audio.set_string_member("bitrate",audio_bitrate);
			audio.set_string_member("quality",audio_quality);
			if (acodec == "opus"){
				audio.set_string_member("opusOptimize",audio_opus_optimize);
			}
			if ((acodec == "aac")||(acodec == "neroaac")||(acodec == "libfdk_aac")){
				audio.set_string_member("aacProfile",audio_profile);
			}
			audio.set_string_member("channels",audio_channels);
			audio.set_string_member("samplingRate",audio_sampling);

			//sox
			audio.set_boolean_member("soxEnabled",sox_enabled);
			if (sox_enabled) {
				audio.set_string_member("soxBass",sox_bass);
				audio.set_string_member("soxTreble",sox_treble);
				audio.set_string_member("soxPitch",sox_pitch);
				audio.set_string_member("soxTempo",sox_tempo);
				audio.set_string_member("soxFadeIn",sox_fade_in);
				audio.set_string_member("soxFadeOut",sox_fade_out);
				audio.set_string_member("soxFadeType",sox_fade_type);
				audio.set_boolean_member("soxNormalize",sox_normalize);
				audio.set_boolean_member("soxEarwax",sox_earwax);
			}
		}

		config.set_object_member("subtitle",subs);
		subs.set_string_member("mode",subtitle_mode);

		var filePath = Folder + "/" + txtPresetName.text + ".json";
		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);

		try{
			json.to_file(filePath);
		} catch (Error e) {
	        log_error (e.message);
	    }

	    //Set the newly saved file as the active script
	    App.SelectedScript = new ScriptFile(filePath);
	}

	public void load_script(){
		var filePath = Folder + "/" + Name + ".json";
		if(file_exists(filePath) == false){ return; }

		txtPresetName.text = Name;

		var parser = new Json.Parser();
        try{
			parser.load_from_file(filePath);
		} catch (Error e) {
	        log_error (e.message);
	    }
        var node = parser.get_root();
        var config = node.get_object();
        Json.Object general = (Json.Object) config.get_object_member("general");
		Json.Object video = (Json.Object) config.get_object_member("video");
		Json.Object audio = (Json.Object) config.get_object_member("audio");
		Json.Object subs = (Json.Object) config.get_object_member("subtitle");

		//general ----------------------------

		format = general.get_string_member("format");
		extension = general.get_string_member("extension");
		//preset_name = general.get_string_member("presetName"); //set from file name
		preset_version = general.get_string_member("presetVersion");
		author_name = general.get_string_member("authorName");
		author_email = general.get_string_member("authorEmail");

		//video --------------------------

		vcodec = video.get_string_member("codec");

		if (vcodec != "disable") {
			switch(vcodec){
				case "x264":
				case "x265":
					x264_profile = video.get_string_member("profile");
					x264_preset = video.get_string_member("preset");
					x264_options = video.get_string_member("options");
					break;
				case "vp8":
				case "vp9":
					if (video.has_member("vpx_deadline")){
						vpx_deadline = video.get_string_member("vpx_deadline");
					}
					if (video.has_member("vpx_speed")){
						vpx_speed = video.get_string_member("vpx_speed");
					}
					break;
			}
			video_mode = video.get_string_member("mode");
			video_bitrate = video.get_string_member("bitrate");
			video_quality = video.get_string_member("quality");

			//video filters ------------------------

			frame_size = video.get_string_member("frameSize");
			frame_width = video.get_string_member("frameWidth");
			frame_height = video.get_string_member("frameHeight");
			resizing_method = video.get_string_member("resizingMethod");
			no_upscaling = video.get_boolean_member("noUpscaling");
			fit_to_box = video.get_boolean_member("fitToBox");
			frame_rate = video.get_string_member("fps");
			frame_rate_num = video.get_string_member("fpsNum");
			frame_rate_denom = video.get_string_member("fpsDenom");
		}

		//audio ---------------------

		acodec = audio.get_string_member("codec");

		if (acodec != "disable") {
			//codec config
			audio_mode = audio.get_string_member("mode");
			audio_bitrate = audio.get_string_member("bitrate");
			audio_quality = audio.get_string_member("quality");
			if (acodec == "opus"){
				audio_opus_optimize = audio.get_string_member("opusOptimize");
			}
			if ((acodec == "aac")||(acodec == "neroaac")||(acodec == "libfdk_aac")){
				audio_profile = audio.get_string_member("aacProfile");
			}
			audio_channels = audio.get_string_member("channels");
			audio_sampling = audio.get_string_member("samplingRate");

			//sox config

			if (audio.get_boolean_member("soxEnabled")){
				App.Encoders["sox"].CheckAvailability();
				if (!App.Encoders["sox"].IsAvailable){
					sox_enabled = false;
				}
				else{
					sox_enabled = true;
				}
			}
			else{
				sox_enabled = false;
			}

			if (sox_enabled) {
				sox_bass = audio.get_string_member("soxBass");
				sox_treble = audio.get_string_member("soxTreble");
				sox_pitch = audio.get_string_member("soxPitch");
				sox_tempo = audio.get_string_member("soxTempo");
				sox_fade_in = audio.get_string_member("soxFadeIn");
				sox_fade_out = audio.get_string_member("soxFadeOut");
				sox_fade_type = audio.get_string_member("soxFadeType");
				sox_normalize = audio.get_boolean_member("soxNormalize");
				sox_earwax = audio.get_boolean_member("soxEarwax");
			}
		}

		//subtitles --------------

		subtitle_mode = subs.get_string_member("mode");
	}


	public string format{
        owned get {
			return gtk_combobox_get_value(cmbFileFormat,1,"mkv");
		}
        set {
			gtk_combobox_set_value(cmbFileFormat,1,value);
		}
    }

	public string extension{
        owned get {
			return gtk_combobox_get_value(cmbFileExtension,1,".mkv");
		}
        set {
			gtk_combobox_set_value(cmbFileExtension,1,value);
		}
    }

    public string author_name{
        owned get {
			return txtAuthorName.text;
		}
        set {
			txtAuthorName.text = value;
		}
    }

    public string author_email{
        owned get {
			return txtAuthorEmail.text;
		}
        set {
			txtAuthorEmail.text = value;
		}
    }

    public string preset_name{
        owned get {
			return txtPresetName.text;
		}
        set {
			txtPresetName.text = value;
		}
    }

    public string preset_version{
        owned get {
			return txtPresetVersion.text;
		}
        set {
			txtPresetVersion.text = value;
		}
    }

	public string vcodec{
        owned get {
			return gtk_combobox_get_value(cmbVCodec,1,"x264");
		}
        set {
			gtk_combobox_set_value(cmbVCodec,1,value);
		}
    }

    public string video_mode{
        owned get {
			return gtk_combobox_get_value(cmbVideoMode,1,"vbr");
		}
        set {
			gtk_combobox_set_value(cmbVideoMode,1,value);
		}
    }

    public string video_bitrate{
        owned get {
			return spinVideoBitrate.get_value().to_string();
		}
        set {
			spinVideoBitrate.set_value(double.parse(value));
		}
    }

    public string video_quality{
        owned get {
			return "%.1f".printf(spinVideoQuality.get_value());
		}
        set {
			spinVideoQuality.get_adjustment().set_value(double.parse(value));
		}
    }

	public string x264_preset {
        owned get {
			return gtk_combobox_get_value(cmbX264Preset,1,"medium");
		}
        set {
			gtk_combobox_set_value(cmbX264Preset,1,value);
		}
    }

    public string x264_profile{
        owned get {
			return gtk_combobox_get_value(cmbX264Profile,1,"high");
		}
        set {
			gtk_combobox_set_value(cmbX264Profile, 1, value);
		}
    }

    public string x264_options{
        owned get {
			return txtVCodecOptions.buffer.text;
		}
        set {
			txtVCodecOptions.buffer.text = value;
		}
    }

    public string vpx_deadline{
        owned get {
			return gtk_combobox_get_value(cmbVpxSpeed,1,"good");
		}
        set {
			gtk_combobox_set_value(cmbVpxSpeed,1,value);
		}
    }

    public string vpx_speed{
        owned get {
			return scaleVpxSpeed.adjustment.value.to_string();
		}
        set {
			scaleVpxSpeed.adjustment.value = int.parse(value);
		}
    }

    public string frame_size{
        owned get {
			return gtk_combobox_get_value(cmbFrameSize,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmbFrameSize, 1, value);
		}
    }

    public string resizing_method{
        owned get {
			return gtk_combobox_get_value(cmbResizingMethod,1,"cubic");
		}
        set {
			gtk_combobox_set_value(cmbResizingMethod, 1, value);
		}
    }

    public string frame_width{
        owned get {
			return spinFrameWidth.get_value().to_string();
		}
        set {
			spinFrameWidth.set_value(double.parse(value));
		}
    }

    public string frame_height{
        owned get {
			return spinFrameHeight.get_value().to_string();
		}
        set {
			spinFrameHeight.set_value(double.parse(value));
		}
    }

	public bool fit_to_box{
        get {
			return chkFitToBox.active;
		}
        set {
			chkFitToBox.set_active((bool)value);
		}
    }

    public bool no_upscaling{
        get {
			return chkNoUpScale.active;
		}
        set {
			chkNoUpScale.set_active((bool)value);
		}
    }

    public string frame_rate{
        owned get {
			return gtk_combobox_get_value(cmbFPS,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmbFPS, 1, value);
		}
    }

    public string frame_rate_num{
        owned get {
			return spinFPSNum.get_value().to_string();
		}
        set {
			spinFPSNum.set_value(double.parse(value));
		}
    }

    public string frame_rate_denom{
        owned get {
			return spinFPSDenom.get_value().to_string();
		}
        set {
			spinFPSDenom.set_value(double.parse(value));
		}
    }

    public string acodec{
        owned get {
			return gtk_combobox_get_value(cmbACodec,1,"mp3lame");
		}
        set {
			gtk_combobox_set_value(cmbACodec,1,value);
		}
    }

    public string audio_mode{
        owned get {
			return gtk_combobox_get_value(cmbAudioMode,1,"vbr");
		}
        set {
			gtk_combobox_set_value(cmbAudioMode, 1, value);
		}
    }

    public string audio_opus_optimize{
        owned get {
			return gtk_combobox_get_value(cmbOpusOptimize,1,"none");
		}
        set {
			gtk_combobox_set_value(cmbOpusOptimize, 1, value);
		}
    }

    public string audio_profile{
        owned get {
			return gtk_combobox_get_value(cmbAacProfile,1,"auto");
		}
        set {
			gtk_combobox_set_value(cmbAacProfile, 1, value);
		}
    }

    public string audio_bitrate{
        owned get {
			return spinAudioBitrate.get_value().to_string();
		}
        set {
			spinAudioBitrate.set_value(double.parse(value));
		}
    }

    public string audio_quality{
        owned get {
			return "%.1f".printf(spinAudioQuality.get_value());
		}
        set {
			spinAudioQuality.set_value(double.parse(value));
		}
    }

    public string audio_channels{
        owned get {
			return gtk_combobox_get_value(cmbAudioChannels,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmbAudioChannels, 1, value);
		}
    }

    public string audio_sampling{
        owned get {
			return gtk_combobox_get_value(cmbAudioSampleRate,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmbAudioSampleRate, 1, value);
		}
    }

    public bool sox_enabled{
        get {
			return switchSox.active;
		}
        set {
			switchSox.set_active((bool)value);
		}
    }

    public string sox_bass{
        owned get {
			return scaleBass.get_value().to_string();
		}
        set {
			scaleBass.set_value(double.parse(value));
		}
    }

    public string sox_treble{
        owned get {
			return scaleTreble.get_value().to_string();
		}
        set {
			scaleTreble.set_value(double.parse(value));
		}
    }

    public string sox_pitch{
        owned get {
			return "%.1f".printf(scalePitch.get_value()/100);
		}
        set {
			scalePitch.set_value(double.parse(value) * 100);
		}
    }

    public string sox_tempo{
        owned get {
			return "%.1f".printf(scaleTempo.get_value()/100);
		}
        set {
			scaleTempo.set_value(double.parse(value) * 100);
		}
    }

    public string sox_fade_in{
        owned get {
			return spinFadeIn.get_value().to_string();
		}
        set {
			spinFadeIn.set_value(double.parse(value));
		}
    }

    public string sox_fade_out{
        owned get {
			return spinFadeOut.get_value().to_string();
		}
        set {
			spinFadeOut.set_value(double.parse(value));
		}
    }

    public string sox_fade_type{
        owned get {
			return gtk_combobox_get_value(cmbFadeType,1,"l");
		}
        set {
			gtk_combobox_set_value(cmbFadeType, 1, value);
		}
    }

    public bool sox_normalize{
        get {
			return switchNormalize.active;
		}
        set {
			switchNormalize.set_active((bool)value);
		}
    }

    public bool sox_earwax{
        get {
			return switchEarWax.active;
		}
        set {
			switchEarWax.set_active((bool)value);
		}
    }

    public string subtitle_mode{
        owned get {
			return gtk_combobox_get_value(cmbSubtitleMode,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmbSubtitleMode, 1, value);
		}
    }
}
