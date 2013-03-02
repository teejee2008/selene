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
using Soup;
using Json;

public class ConfigWindow : Dialog {
	
	public string Folder;
	public string Name;
	public bool CreateNew = false;
	
	private Notebook tabMain;
	private Box vboxMain;

	private Label lblGeneral;
	private Grid gridGeneral;
	
	private Label lblVideo;
	private Grid gridVideo;
	
	private Label lblAudio;
	private Grid gridAudio;
	
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
	
	private ComboBox cmbX264Preset;
	private Label lblX264Preset;
	//private Scale scaleX264Preset;
	
	private ComboBox cmbX264Profile;
	private Label lblX264Profile;
	//private Scale scaleX264Profile;
	
	private Label lblCRF;
	private SpinButton spinCRF;
	//private Scale scaleCRF;

	private Label lblHeaderFileFormat;
	private Label lblHeaderPreset;
	private Label lblHeaderFrameSize;
	private Label lblHeaderFrameRate;
	private Label lblHeaderAudioSampleRate;
	private Label lblHeaderAudioChannels;
	
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
	
	private Label lblAudioMode;
	private ComboBox cmbAudioMode;
	
	private Label lblAudioBitrate;
	private SpinButton spinAudioBitrate;
	
	private Label lblAudioQuality;
	private SpinButton spinAudioQuality;
	
	private Label lblOpusOptimize;
	private ComboBox cmbOpusOptimize;
	
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
	
	private Button btnSave;
	private Button btnCancel;
	
	public ConfigWindow () 
	{
		this.deletable = false; // remove window close button
		this.modal = true;
		set_default_size (350, 450);	
		
		int row = 0;
        Gtk.ListStore model;
        Gtk.CellRendererText textCell;
        Gtk.TreeIter iter;
        
		//get content area
		vboxMain = get_content_area ();
		vboxMain.margin = 6;
		
		//tabMain
		tabMain = new Notebook ();
		vboxMain.pack_start (tabMain, true, true, 0);
		
		//General tab ---------------------------------------------
		
		//lblGeneral
		lblGeneral = new Label ("General");

        //gridGeneral
        gridGeneral = new Grid ();
        gridGeneral.set_column_spacing (6);
        gridGeneral.set_row_spacing (6);
        gridGeneral.margin = 12;
        gridGeneral.visible = false;
        tabMain.append_page (gridGeneral, lblGeneral);
		
		row = -1;
		
		//lblHeaderFileFormat
		lblHeaderFileFormat = new Gtk.Label("<b>File Format &amp; Extension:</b>");
		lblHeaderFileFormat.set_use_markup(true);
		lblHeaderFileFormat.xalign = (float) 0.0;
		//lblHeaderFileFormat.margin_top = 6;
		lblHeaderFileFormat.margin_bottom = 6;
		gridGeneral.attach(lblHeaderFileFormat,0,++row,2,1);
				
		//lblFileFormat
		lblFileFormat = new Gtk.Label("Format");
		lblFileFormat.xalign = (float) 0.0;
		gridGeneral.attach(lblFileFormat,0,++row,1,1);
		
		//cmbFileFormat
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		
		model.append (out iter);
		model.set (iter,0,"Matroska Video (*.mkv)",1,"mkv");
		model.append (out iter);
		model.set (iter,0,"MPEG4 Video (*.mp4)",1,"mp4v");
		
		/*model.append (out iter);
		model.set (iter,0,"OGG Theora Video (*.ogv)",1,"ogv");
		
		model.append (out iter);
		model.set (iter,0,"FLAC Audio (*.flac)",1,"flac");
		model.append (out iter);
		model.set (iter,0,"OGG Vorbis Audio (*.ogg)",1,"ogg");
		
		model.append (out iter);
		model.set (iter,0,"MP2 Audio (*.mp2)",1,"mp2");*/
		model.append (out iter);
		model.set (iter,0,"MP3 Audio (*.mp3)",1,"mp3");
		model.append (out iter);
		model.set (iter,0,"MP4 Audio (*.mp4)",1,"mp4a");
		model.append (out iter);
		model.set (iter,0,"Opus Audio (*.opus)",1,"opus");
		
		cmbFileFormat = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbFileFormat.pack_start( textCell, false );
        cmbFileFormat.set_attributes( textCell, "text", 0 );
        cmbFileFormat.changed.connect(cmbFileFormat_changed);
        gridGeneral.attach(cmbFileFormat,1,row,1,1);

        //lblFileExtension
		lblFileExtension = new Gtk.Label("Extension");
		lblFileExtension.xalign = (float) 0.0;
		gridGeneral.attach(lblFileExtension,0,++row,1,1);

		cmbFileExtension = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbFileExtension.pack_start( textCell, false );
        cmbFileExtension.set_attributes( textCell, "text", 0 );
        gridGeneral.attach(cmbFileExtension,1,row,1,1);
        
        //lblHeaderPreset
		lblHeaderPreset = new Gtk.Label("<b>Preset Properties:</b>");
		lblHeaderPreset.set_use_markup(true);
		lblHeaderPreset.xalign = (float) 0.0;
		lblHeaderPreset.margin_top = 6;
		lblHeaderPreset.margin_bottom = 6;
		gridGeneral.attach(lblHeaderPreset,0,++row,2,1);
		
        //lblPresetName
		lblPresetName = new Gtk.Label("Name");
		lblPresetName.xalign = (float) 0.0;
		gridGeneral.attach(lblPresetName,0,++row,1,1);
		
		//txtPresetName
		txtPresetName = new Gtk.Entry();
		txtPresetName.xalign = (float) 0.0;
		txtPresetName.text = "New Preset";
		txtPresetName.hexpand = true;
		gridGeneral.attach(txtPresetName,1,row,1,1);
		
		//lblPresetVersion
		lblPresetVersion = new Gtk.Label("Version");
		lblPresetVersion.xalign = (float) 0.0;
		gridGeneral.attach(lblPresetVersion,0,++row,1,1);
		
		//txtPresetVersion
		txtPresetVersion = new Gtk.Entry();
		txtPresetVersion.xalign = (float) 0.0;
		txtPresetVersion.text = "1.0";
		gridGeneral.attach(txtPresetVersion,1,row,1,1);
		
        //lblAuthorName
		lblAuthorName = new Gtk.Label("Author");
		lblAuthorName.xalign = (float) 0.0;
		gridGeneral.attach(lblAuthorName,0,++row,1,1);
		
		//txtAuthorName
		txtAuthorName = new Gtk.Entry();
		txtAuthorName.xalign = (float) 0.0;
		txtAuthorName.text = "";
		gridGeneral.attach(txtAuthorName,1,row,1,1);
		
		//lblAuthorEmail
		lblAuthorEmail = new Gtk.Label("Email");
		lblAuthorEmail.xalign = (float) 0.0;
		gridGeneral.attach(lblAuthorEmail,0,++row,1,1);
		
		//txtAuthorEmail
		txtAuthorEmail = new Gtk.Entry();
		txtAuthorEmail.xalign = (float) 0.0;
		txtAuthorEmail.text = "";
		gridGeneral.attach(txtAuthorEmail,1,row,1,1);
		
		//Video tab ---------------------------------------------
		
		//lblVideo
		lblVideo = new Label("Video");

        //gridVideo
        gridVideo = new Grid ();
        gridVideo.set_column_spacing (6);
        gridVideo.set_row_spacing (6);
        gridVideo.visible = false;
        gridVideo.margin = 12;
        tabMain.append_page (gridVideo, lblVideo);
		
		row = -1;
		
		//lblVCodec
		lblVCodec = new Gtk.Label("Format / Codec");
		lblVCodec.xalign = (float) 0.0;
		lblVCodec.hexpand = true;
		gridVideo.attach(lblVCodec,0,++row,2,1);
		
		//cmbVCodec
		cmbVCodec = new ComboBox();
		textCell = new CellRendererText();
        cmbVCodec.pack_start( textCell, false );
        cmbVCodec.set_attributes( textCell, "text", 0 );
        cmbVCodec.changed.connect(cmbVCodec_changed);
        gridVideo.attach(cmbVCodec,1,row,1,1);
        
        //lblPreset
		lblX264Preset = new Gtk.Label("Preset");
		lblX264Preset.xalign = (float) 0.0;
		lblX264Preset.set_tooltip_text (
"""Compression Vs Encoding Speed

Faster Preset = Faster Encoding, Larger Files
Slower Preset = Slower Encoding, Smaller Files

This option only affects Encoding Speed and File Size.
It does not affect Video Quality (which is controlled by CRF value)"""
		);
		gridVideo.attach(lblX264Preset,0,++row,2,1);
		
		//cmbx264Preset
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, "UltraFast", 1, "ultrafast");
		model.append (out iter);
		model.set (iter, 0, "SuperFast", 1, "superfast");
		model.append (out iter);
		model.set (iter, 0, "Fast", 1, "fast");
		model.append (out iter);
		model.set (iter, 0, "Medium", 1, "medium");
		model.append (out iter);
		model.set (iter, 0, "Slow", 1, "slow");
		model.append (out iter);
		model.set (iter, 0, "Slower", 1, "slower");
		model.append (out iter);
		model.set (iter, 0, "VerySlow", 1, "veryslow");
		
		cmbX264Preset = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbX264Preset.pack_start( textCell, false );
        cmbX264Preset.set_attributes( textCell, "text", 0 );
        gridVideo.attach(cmbX264Preset,1,row,1,1);

		//lblProfile
		lblX264Profile = new Gtk.Label("Profile");
		lblX264Profile.xalign = (float) 0.0;
		lblX264Profile.set_tooltip_text (
"""Compression Vs Device Compatibility

Baseline = Worse compression, Playable on more devices (mobiles and PMPs)
High Profile = Best compression, Not playable on some devices

Change this option only if you are encoding for a particular device"""
		);
		gridVideo.attach(lblX264Profile,0,++row,1,1);
	
		//cmbX264Profile
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
		
		cmbX264Profile = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbX264Profile.pack_start( textCell, false );
        cmbX264Profile.set_attributes( textCell, "text", 0 );
        gridVideo.attach(cmbX264Profile,1,row,1,1);
        
        //lblCrf
		lblCRF = new Gtk.Label("CRF");
		lblCRF.xalign = (float) 0.0;
		lblCRF.set_tooltip_text (
"""Compression Vs Quality

Smaller values = Better quality, Larger Files
Larger values  = Less quality, Smaller files"""
		);
		gridVideo.attach(lblCRF,0,++row,1,1);

		//adjCRF
		Gtk.Adjustment adjCRF = new Gtk.Adjustment(22.0, 0.0, 51.0, 0.1, 1.0, 0.0);

		//spinCRF
		spinCRF = new Gtk.SpinButton (adjCRF, 0.1, 2);
		gridVideo.attach(spinCRF,1,row,1,1);
		
		//lblVCodecOptions
		lblVCodecOptions = new Gtk.Label("X264 Options");
		lblVCodecOptions.xalign = (float) 0.0;
		gridVideo.attach(lblVCodecOptions,0,++row,1,1);
		
		//txtVCodecOptions
		txtVCodecOptions = new Gtk.TextView ();
		TextBuffer buff = new TextBuffer(null);
		txtVCodecOptions.buffer = buff;
		txtVCodecOptions.editable = true;
		txtVCodecOptions.buffer.text = "";
		txtVCodecOptions.expand = true;
		txtVCodecOptions.set_wrap_mode (Gtk.WrapMode.WORD);
		
		Gtk.ScrolledWindow scrollWin = new Gtk.ScrolledWindow (null, null);
		scrollWin.set_shadow_type (ShadowType.ETCHED_IN);
		scrollWin.add (txtVCodecOptions);
		gridVideo.attach(scrollWin,0,++row,2,1);
		
		//Video Filters tab ---------------------------------------------
		
		//lblVideoFilters
		lblVideoFilters = new Label ("Filters");

        //gridVideoFilters
        gridVideoFilters = new Grid ();
        gridVideoFilters.set_column_spacing (6);
        gridVideoFilters.set_row_spacing (6);
        gridVideoFilters.margin = 12;
        gridVideoFilters.visible = false;
        tabMain.append_page (gridVideoFilters, lblVideoFilters);
		
		row = -1;
		
		//lblHeaderFrameSize
		lblHeaderFrameSize = new Gtk.Label("<b>Resize:</b>");
		lblHeaderFrameSize.set_use_markup(true);
		lblHeaderFrameSize.xalign = (float) 0.0;
		lblHeaderFrameSize.margin_bottom = 6;
		gridVideoFilters.attach(lblHeaderFrameSize,0,++row,1,1);
		
		//lblFrameSize
		lblFrameSize = new Gtk.Label("Resolution");
		lblFrameSize.xalign = (float) 0.0;
		gridVideoFilters.attach(lblFrameSize,0,++row,1,1);
		
		//cmbFrameSize
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,"No Change",1,"disable");
		model.append (out iter);
		model.set (iter,0,"Custom",1,"custom");
		model.append (out iter);
		model.set (iter,0,"320p",1,"320p");
		model.append (out iter);
		model.set (iter,0,"480p",1,"480p");
		model.append (out iter);
		model.set (iter,0,"720p",1,"720p");
		model.append (out iter);
		model.set (iter,0,"1080p",1,"1080p");
		
		cmbFrameSize = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        cmbFrameSize.pack_start( textCell, false );
        cmbFrameSize.set_attributes( textCell, "text", 0 );
        cmbFrameSize.changed.connect(cmbFrameSize_changed);
        gridVideoFilters.attach(cmbFrameSize,1,row,1,1);

        //lblFrameSizeCustom
		lblFrameSizeCustom = new Gtk.Label("Width x Height");
		lblFrameSizeCustom.xalign = (float) 0.0;
		lblFrameSizeCustom.no_show_all = true;
		lblFrameSizeCustom.set_tooltip_text (
"""Set either Width or Height, leave the other as 0 (it will be calculated automatically).
Setting both width and height is not recommended, since the video may get stretched or squeezed.

Examples:
0 x 0   => No Change
0 x 480 => sets Height to 480 and Width is calculated automatically
800 x 0 => sets Width to 800 and Height is calculated automatically""");
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
		spinFrameWidth.set_tooltip_text ("Width");
		hboxFrameSize.pack_start (spinFrameWidth, false, false, 0);

		//spinHeight
		Gtk.Adjustment adjHeight = new Gtk.Adjustment(480, 0, 999999, 1, 16, 0);
		spinFrameHeight = new Gtk.SpinButton (adjHeight, 1, 0);
		spinFrameHeight.xalign = (float) 0.5;
		spinFrameHeight.no_show_all = true;
		spinFrameHeight.width_chars = 5;
		spinFrameHeight.set_tooltip_text ("Height");
		hboxFrameSize.pack_start (spinFrameHeight, false, false, 5);
		
		//lblResizingMethod
		lblResizingMethod = new Gtk.Label("Resizing Method");
		lblResizingMethod.xalign = (float) 0.0;
		gridVideoFilters.attach(lblResizingMethod,0,++row,1,1);

		//cmbResizingMethod
		cmbResizingMethod = new ComboBox();
		textCell = new CellRendererText();
        cmbResizingMethod.pack_start(textCell, false);
        cmbResizingMethod.set_attributes(textCell, "text", 0);
        cmbResizingMethod.changed.connect(cmbAudioMode_changed);
        cmbResizingMethod.hexpand = true;
        cmbResizingMethod.set_tooltip_text (
"""The resizing filter affects the sharpness and compressibility of the video.
For example, the 'Lanzos' filter gives sharper video but the extra detail results in slightly bigger files.
The 'Bilinear' filter gives smoother video (less detail) which results in slightly smaller files""");
        gridVideoFilters.attach(cmbResizingMethod,1,row,1,1);
        
        //populate
        model = new Gtk.ListStore (2, typeof (string), typeof (string));
        cmbResizingMethod.set_model(model);
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

		//chkFitToBox
		chkFitToBox = new CheckButton.with_label("Do not stretch or squeeze the video (Fit-to-box)");
		chkFitToBox.active = true;
		gridVideoFilters.attach(chkFitToBox,0,++row,2,1);
		
		//chkNoUpScale
		chkNoUpScale = new CheckButton.with_label("No Up-Scaling");
		chkNoUpScale.active = true;
		gridVideoFilters.attach(chkNoUpScale,0,++row,2,1);

		//lblHeaderFrameRate
		lblHeaderFrameRate = new Gtk.Label("<b>Resample:</b>");
		lblHeaderFrameRate.set_use_markup(true);
		lblHeaderFrameRate.xalign = (float) 0.0;
		lblHeaderFrameRate.margin_top = 6;
		lblHeaderFrameRate.margin_bottom = 6;
		gridVideoFilters.attach(lblHeaderFrameRate,0,++row,1,1);
		
		//lblFPS
		lblFPS = new Gtk.Label("Frame Rate");
		lblFPS.xalign = (float) 0.0;
		lblFPS.set_tooltip_text ("");
		gridVideoFilters.attach(lblFPS,0,++row,1,1);
		
		//cmbFPS
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,"No Change",1,"disable");
		model.append (out iter);
		model.set (iter,0,"Custom",1,"custom");
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
		lblFPSCustom = new Gtk.Label("FPS Ratio");
		lblFPSCustom.xalign = (float) 0.0;
		lblFPSCustom.no_show_all = true;
		lblFPSCustom.set_tooltip_text (
"""Examples:
0 / 0  => No Change
25 / 1 => 25fps
30 / 1 => 30fps
30000 / 1001 => 29.97fps""");
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
		spinFPSNum.set_tooltip_text ("Frames/sec Numerator");
		hboxFPS.pack_start(spinFPSNum, false, false, 0);
		
		//spinFPSDenom
		Gtk.Adjustment adjFPSDenom = new Gtk.Adjustment(0, 0, 999999, 1, 1, 0);
		spinFPSDenom = new Gtk.SpinButton (adjFPSDenom, 1, 0);
		spinFPSDenom.xalign = (float) 0.5;
		spinFPSDenom.no_show_all = true;
		spinFPSDenom.width_chars = 5;
		spinFPSDenom.set_tooltip_text ("Frames/sec Denominator");
		hboxFPS.pack_start(spinFPSDenom, false, false, 5);
				
		// Audio tab --------------------------------------------------
		
		//lblAudio
		lblAudio = new Label ("Audio");

        //gridAudio
        gridAudio = new Grid ();
        gridAudio.set_column_spacing (6);
        gridAudio.set_row_spacing (6);
        gridAudio.margin = 12;
        gridAudio.visible = false;
        tabMain.append_page (gridAudio, lblAudio);
		
		row = -1;
		
		//lblACodec
		lblACodec = new Gtk.Label("Format / Codec");
		lblACodec.xalign = (float) 0.0;
		lblACodec.hexpand = true;
		gridAudio.attach(lblACodec,0,++row,2,1);
		
		//cmbACodec
		cmbACodec = new ComboBox();
		textCell = new CellRendererText();
        cmbACodec.pack_start(textCell, false);
        cmbACodec.set_attributes(textCell, "text", 0);
        cmbACodec.changed.connect(cmbACodec_changed);
        gridAudio.attach(cmbACodec,1,row,1,1);
        
		//lblAudioMode
		lblAudioMode = new Gtk.Label("Encoding Mode");
		lblAudioMode.xalign = (float) 0.0;
		gridAudio.attach(lblAudioMode,0,++row,1,1);

		//cmbAudioMode
		cmbAudioMode = new ComboBox();
		textCell = new CellRendererText();
        cmbAudioMode.pack_start(textCell, false);
        cmbAudioMode.set_attributes(textCell, "text", 0);
        cmbAudioMode.changed.connect(cmbAudioMode_changed);
        cmbAudioMode.hexpand = true;
        gridAudio.attach(cmbAudioMode,1,row,1,1);
        
		//lblAudioBitrate
		lblAudioBitrate = new Gtk.Label("Bitrate (kbps)");
		lblAudioBitrate.xalign = (float) 0.0;
		gridAudio.attach(lblAudioBitrate,0,++row,1,1);
		
		//spinAudioBitrate
		Gtk.Adjustment adjAudioBitrate = new Gtk.Adjustment(128, 32, 320, 1, 1, 0);
		spinAudioBitrate = new Gtk.SpinButton (adjAudioBitrate, 1, 0);
		spinAudioBitrate.xalign = (float) 0.5;
		gridAudio.attach(spinAudioBitrate,1,row,1,1);
		
		//lblAudioQuality
		lblAudioQuality = new Gtk.Label("Quality");
		lblAudioQuality.xalign = (float) 0.0;
		gridAudio.attach(lblAudioQuality,0,++row,1,1);
		
		//spinAudioQuality
		Gtk.Adjustment adjAudioQuality = new Gtk.Adjustment(4, 0, 9, 1, 1, 0);
		spinAudioQuality = new Gtk.SpinButton (adjAudioQuality, 1, 0);
		spinAudioQuality.xalign = (float) 0.5;
		gridAudio.attach(spinAudioQuality,1,row,1,1);
		
		//lblOpusOptimize
		lblOpusOptimize = new Gtk.Label("Optimization");
		lblOpusOptimize.xalign = (float) 0.0;
		gridAudio.attach(lblOpusOptimize,0,++row,1,1);

		//cmbOpusOptimize
		cmbOpusOptimize = new ComboBox();
		textCell = new CellRendererText();
        cmbOpusOptimize.pack_start(textCell, false);
        cmbOpusOptimize.set_attributes(textCell, "text", 0);
        cmbOpusOptimize.hexpand = true;
        gridAudio.attach(cmbOpusOptimize,1,row,1,1);
        
        //populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,"None",1,"none");
		model.append (out iter);
		model.set (iter,0,"Speech",1,"speech");
		model.append (out iter);
		model.set (iter,0,"Music",1,"music");
		cmbOpusOptimize.set_model(model);
		
		//Audio Filters tab ---------------------------------------------
		
		//lblAudioFilters
		lblAudioFilters = new Label ("Audio Processing");

        //gridAudioFilters
        gridAudioFilters = new Grid ();
        gridAudioFilters.set_column_spacing (6);
        gridAudioFilters.set_row_spacing (6);
        gridAudioFilters.margin = 12;
        gridAudioFilters.visible = false;
        tabMain.append_page (gridAudioFilters, lblAudioFilters);
		
		row = -1;
		
		//lblAudioSampleRate
		lblAudioSampleRate = new Gtk.Label("Sampling Rate (Hz)");
		lblAudioSampleRate.xalign = (float) 0.0;
		gridAudioFilters.attach(lblAudioSampleRate,0,++row,1,1);
		
		//cmbAudioSampleRate
		cmbAudioSampleRate = new ComboBox();
		textCell = new CellRendererText();
        cmbAudioSampleRate.pack_start(textCell, false);        
        cmbAudioSampleRate.hexpand = true;
        //cmbAudioSampleRate.entry_text_column = 0;
        cmbAudioSampleRate.set_attributes(textCell, "text", 0);
        gridAudioFilters.attach(cmbAudioSampleRate,1,row,1,1);
        
		//lblAudioChannels
		lblAudioChannels = new Gtk.Label("Channels");
		lblAudioChannels.xalign = (float) 0.0;
		gridAudioFilters.attach(lblAudioChannels,0,++row,1,1);
		
		//cmbAudioChannels
		cmbAudioChannels = new ComboBox();
		textCell = new CellRendererText();
        cmbAudioChannels.pack_start(textCell, false);
        cmbAudioChannels.hexpand = true;
        //cmbAudioChannels.entry_text_column = 0;
        cmbAudioChannels.set_attributes(textCell, "text", 0);
        gridAudioFilters.attach(cmbAudioChannels,1,row,1,1);
		
		//defaults
		cmbFileFormat.set_active(0);
		cmbAudioMode.set_active(0);
		cmbOpusOptimize.set_active(0);
		cmbX264Preset.set_active(3);
		cmbX264Profile.set_active(2);
		cmbFPS.set_active (0);
		cmbFrameSize.set_active (0);
		cmbResizingMethod.set_active (2);
		cmbFileExtension.set_active (0);
		
		// Actions ----------------------------------------------
		
        //btnSave
        btnSave = (Button) add_button (Stock.SAVE, Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (btnSave_clicked);
        
        //btnCancel
        btnCancel = (Button) add_button (Stock.CANCEL, Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (() => { this.destroy (); });
	}

	private void cmbFileFormat_changed ()
	{
		ListStore model;
		TreeIter iter;
		
		string format = Utility.Combo_GetSelectedValue(cmbFileFormat,1,"mkv");

		//populate file extensions ---------------------------
		
		model = new ListStore(2, typeof(string), typeof(string));
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
			case "mp4v":
				model.append (out iter);
				model.set (iter,0,"X264 / H.264 / AVC",1,"x264");
				cmbVCodec.set_active(0);
				break;
			case "mp3":
			case "mp4a":
			case "opus":
				model.append (out iter);
				model.set (iter,0,"Disable Video",1,"disable");
				cmbVCodec.set_active(0);
				break;
		}
		
		switch (format) {
			case "mp3":
			case "mp4a":
			case "opus":
				gridVideo.sensitive = false;
				gridVideoFilters.sensitive = false;
				break;
			default:
				gridVideo.sensitive = true;
				gridVideoFilters.sensitive = true;
				break;
		}
		
		//populate audio codecs ---------------------------
		
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbACodec.set_model(model);
		
		switch (format) {
			case "mkv":
				model.append (out iter);
				model.set (iter,0,"Disable Audio",1,"disable");
				model.append (out iter);
				model.set (iter,0,"MP3 / LAME",1,"mp3lame");
				cmbACodec.set_active(1);
				break;
			
			case "mp4v":
				model.append (out iter);
				model.set (iter,0,"Disable Audio",1,"disable");
				model.append (out iter);
				model.set (iter,0,"AAC / Nero",1,"neroaac");
				cmbACodec.set_active(1);
				break;
				
			case "mp3":
				model.append (out iter);
				model.set (iter,0,"MP3 / LAME",1,"mp3lame");
				cmbACodec.set_active(0);
				break;
			
			case "mp4a":
				model.append (out iter);
				model.set (iter,0,"AAC / Nero",1,"neroaac");
				cmbACodec.set_active(0);
				break;
				
			case "opus":
				model.append (out iter);
				model.set (iter,0,"Opus",1,"opus");
				cmbACodec.set_active(0);
				break;
		}
	}
	
	private void cmbACodec_changed ()
	{
		ListStore model;
		TreeIter iter;

		//show & hide options
		switch (acodec){
			case "opus":
				lblAudioQuality.visible = false;
				spinAudioQuality.visible = false;
				lblOpusOptimize.visible = true;
				cmbOpusOptimize.visible = true;
				break;
			default:
				lblAudioQuality.visible = true;
				spinAudioQuality.visible = true;
				lblOpusOptimize.visible = false;
				cmbOpusOptimize.visible = false;
				break;
		}
		
		//disable options when audio is disabled
		switch (acodec){
			case "disable":
				gridAudioFilters.sensitive = false;
				break;
			default:
				gridAudioFilters.sensitive = true;
				break;
		}
		
		//populate encoding modes
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbAudioMode.set_model(model);
		
		switch (acodec){
			case "mp3lame":
				model.append (out iter);
				model.set (iter,0,"Variable Bitrate",1,"vbr");
				model.append (out iter);
				model.set (iter,0,"Average Bitrate",1,"abr");
				model.append (out iter);
				model.set (iter,0,"Constant Bitrate",1,"cbr");
				model.append (out iter);
				model.set (iter,0,"Constant Bitrate (Strict)",1,"cbr-strict");
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
				
			case "neroaac":
				model.append (out iter);
				model.set (iter,0,"Variable Bitrate",1,"vbr");
				model.append (out iter);
				model.set (iter,0,"Average Bitrate",1,"abr");
				model.append (out iter);
				model.set (iter,0,"Constant Bitrate",1,"cbr");
				cmbAudioMode.set_active(0);
				
				spinAudioBitrate.adjustment.configure(160, 8, 400, 1, 1, 0);
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
				model.set (iter,0,"Variable Bitrate",1,"vbr");
				model.append (out iter);
				model.set (iter,0,"Average Bitrate",1,"abr");
				model.append (out iter);
				model.set (iter,0,"Constant Bitrate",1,"cbr");
				cmbAudioMode.set_active(0);
				
				spinAudioBitrate.adjustment.configure(128, 6, 2000, 1, 1, 0);
				spinAudioBitrate.set_tooltip_text ("");
				spinAudioBitrate.digits = 0;
				
				cmbAudioMode.sensitive = true;
				cmbAudioMode_changed();
				break;
				
			default: //disable
				cmbAudioMode.sensitive = false;
				spinAudioBitrate.sensitive = false;
				spinAudioQuality.sensitive = false;
				break;
		}
		
		//populate sampling rates
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbAudioSampleRate.set_model(model);
		switch (acodec){
			case "mp3lame":
				model.append (out iter);
				model.set (iter,0,"No Change",1,"disable");
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
				
			case "neroaac":
				model.append (out iter);
				model.set (iter,0,"No Change",1,"disable");
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
				
			case "opus":
				model.append (out iter);
				model.set (iter,0,"No Change",1,"disable");
				model.append (out iter);
				model.set (iter,0,"44100",1,"44100");
				cmbAudioSampleRate.set_active(0);
				break;
		}
		
		//populate channels
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmbAudioChannels.set_model(model);
		switch (acodec){
			case "neroaac":
			case "opus":
				model.append (out iter);
				model.set (iter,0,"No Change",1,"disable");
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
				cmbAudioChannels.set_active(0);
				break;
			default:
				model.append (out iter);
				model.set (iter,0,"No Change",1,"disable");
				model.append (out iter);
				model.set (iter,0,"1",1,"1");
				model.append (out iter);
				model.set (iter,0,"2",1,"2");
				cmbAudioChannels.set_active(0);
				break;
		}
	}
	
	private void cmbAudioMode_changed()
	{
		switch (Utility.Combo_GetSelectedValue(cmbAudioMode,1,"vbr")) {
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
	
	private void cmbFrameSize_changed()
	{
		if (Utility.Combo_GetSelectedValue(cmbFrameSize,1,"disable") == "custom") {
			spinFrameWidth.sensitive = true;
			spinFrameHeight.sensitive = true;
		}
		else{
			spinFrameWidth.sensitive = false;
			spinFrameHeight.sensitive = false;
		}
		
		if (Utility.Combo_GetSelectedValue(cmbFrameSize,1,"disable") == "disable") {
			cmbResizingMethod.sensitive = false;
			chkFitToBox.sensitive = false;
			chkNoUpScale.sensitive = false;
		}
		else {
			cmbResizingMethod.sensitive = true;
			chkFitToBox.sensitive = true;
			chkNoUpScale.sensitive = true;
		}
		
		switch (Utility.Combo_GetSelectedValue(cmbFrameSize,1,"disable")) {
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
		if (Utility.Combo_GetSelectedValue(cmbFrameSize,1,"disable") == "disable"){
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

	private void cmbFPS_changed()
	{
		if (Utility.Combo_GetSelectedValue(cmbFPS,1,"disable") == "custom") {
			spinFPSNum.sensitive = true;
			spinFPSDenom.sensitive = true;
		}
		else{
			spinFPSNum.sensitive = false;
			spinFPSDenom.sensitive = false;
		}
		
		switch (Utility.Combo_GetSelectedValue(cmbFPS,1,"disable")) {
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
		if (Utility.Combo_GetSelectedValue(cmbFPS,1,"disable") == "disable"){
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
	
	private void cmbVCodec_changed ()
	{
		
		
	}
	
	private void btnSave_clicked ()
	{
		if (txtPresetName.text.length < 1) {
			tabMain.page = 0;
			Utility.messagebox_show("Empty Preset Name","Please enter a name for this preset",true);
			return;
		}
		
		save_script();
		this.destroy ();
	}

	private void save_script()
	{
		var config = new Json.Object();
		var general = new Json.Object();
		var video = new Json.Object();
		var audio = new Json.Object();
		
		config.set_object_member("general",general);
		general.set_string_member("format",format);
		general.set_string_member("extension",extension);
		general.set_string_member("authorName",author_name);
		general.set_string_member("authorEmail",author_email);
		general.set_string_member("presetName",preset_name);
		general.set_string_member("presetVersion",preset_version);
		
		config.set_object_member("video",video);
		video.set_string_member("codec",vcodec);
		video.set_string_member("profile",x264_profile);
		video.set_string_member("preset",x264_preset);
		video.set_string_member("crf",x264_crf);
		video.set_string_member("options",x264_options);
		video.set_string_member("frameSize",frame_size);
		video.set_string_member("frameWidth",frame_width);
		video.set_string_member("frameHeight",frame_height);
		video.set_string_member("resizingMethod",resizing_method);
		video.set_boolean_member("noUpscaling",no_upscaling);
		video.set_boolean_member("fitToBox",fit_to_box);
		video.set_string_member("fpsNum",frame_rate_num);
		video.set_string_member("fpsDenom",frame_rate_denom);
		
		config.set_object_member("audio",audio);
		audio.set_string_member("codec",acodec);
		audio.set_string_member("mode",audio_mode);
		audio.set_string_member("bitrate",audio_bitrate);
		audio.set_string_member("quality",audio_quality);
		audio.set_string_member("opusOptimize",audio_opus_optimize);
		audio.set_string_member("channels",audio_channels);
		audio.set_string_member("samplingRate",audio_sampling);
		
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
	
	public void load_script()
	{
		var filePath = Folder + "/" + Name + ".json";
		if(Utility.file_exists(filePath) == false){ return; }
		
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
		
		format = general.get_string_member("format");
		extension = general.get_string_member("extension");
		//preset_name = general.get_string_member("presetName"); //set from file name
		preset_version = general.get_string_member("presetVersion");
		author_name = general.get_string_member("authorName");
		author_email = general.get_string_member("authorEmail");
		
		switch(video.get_string_member("codec"))
		{
			case "x264":
				x264_profile = video.get_string_member("profile");
				x264_preset = video.get_string_member("preset");
				x264_crf = video.get_string_member("crf");
				x264_options = video.get_string_member("options");
				break;
		}
		
		frame_size = video.get_string_member("frameSize");
		frame_width = video.get_string_member("frameWidth");
		frame_height = video.get_string_member("frameHeight");
		resizing_method = video.get_string_member("resizingMethod");
		no_upscaling = video.get_boolean_member("noUpscaling");
		fit_to_box = video.get_boolean_member("fitToBox");
		frame_rate_num = video.get_string_member("fpsNum");
		frame_rate_denom = video.get_string_member("fpsDenom");
				
		switch(audio.get_string_member("codec"))
		{
			case "mp3lame":
			case "neroaac":
				audio_mode = audio.get_string_member("mode");
				audio_bitrate = audio.get_string_member("bitrate");
				audio_quality = audio.get_string_member("quality");
				break;
			case "opus":
				audio_mode = audio.get_string_member("mode");
				audio_bitrate = audio.get_string_member("bitrate");
				audio_opus_optimize = audio.get_string_member("opusOptimize");
				break;
		}
		
		audio_channels = audio.get_string_member("channels");
		audio_sampling = audio.get_string_member("samplingRate");
	}

	public string format
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbFileFormat,1,"mkv");
		}
        set { 
			Utility.Combo_SelectValue(cmbFileFormat,1,value);
		}
    }

	public string extension
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbFileExtension,1,".mkv");
		}
        set { 
			Utility.Combo_SelectValue(cmbFileExtension,1,value);
		}
    }
    
    public string author_name
	{
        owned get { 
			return txtAuthorName.text;
		}
        set { 
			txtAuthorName.text = value;
		}
    }
    
    public string author_email
	{
        owned get { 
			return txtAuthorEmail.text;
		}
        set { 
			txtAuthorEmail.text = value;
		}
    }
    
    public string preset_name
	{
        owned get { 
			return txtPresetName.text;
		}
        set { 
			txtPresetName.text = value;
		}
    }
    
    public string preset_version
	{
        owned get { 
			return txtPresetVersion.text;
		}
        set { 
			txtPresetVersion.text = value;
		}
    }
    
	public string vcodec
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbVCodec,1,"x264");
		}
        set { 
			Utility.Combo_SelectValue(cmbVCodec,1,value);
		}
    }
    
	public string x264_preset 
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbX264Preset,1,"medium");
		}
        set { 
			Utility.Combo_SelectValue(cmbX264Preset,1,value);
		}
    }
    
    public string x264_profile
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbX264Profile,1,"high");
		}
        set { 
			Utility.Combo_SelectValue(cmbX264Profile, 1, value);
		}
    }
    
    public string x264_crf 
	{
        owned get { 
			return spinCRF.get_value().to_string(); 
		}
        set { 
			spinCRF.get_adjustment().set_value(double.parse(value));
		}
    }
    
    public string x264_options
	{
        owned get { 
			return txtVCodecOptions.buffer.text;
		}
        set { 
			txtVCodecOptions.buffer.text = value;
		}
    }
    
    public string frame_size
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbFrameSize,1,"disable");
		}
        set { 
			Utility.Combo_SelectValue(cmbFrameSize, 1, value);
		}
    }
    
    public string resizing_method
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbResizingMethod,1,"cubic");
		}
        set { 
			Utility.Combo_SelectValue(cmbResizingMethod, 1, value);
		}
    }
    
    public string frame_width
	{
        owned get { 
			return spinFrameWidth.get_value().to_string(); 
		}
        set { 
			spinFrameWidth.set_value(double.parse(value));
		}
    }
    
    public string frame_height
	{
        owned get { 
			return spinFrameHeight.get_value().to_string(); 
		}
        set { 
			spinFrameHeight.set_value(double.parse(value));
		}
    }
	
	public bool fit_to_box
	{
        get { 
			return chkFitToBox.active; 
		}
        set { 
			chkFitToBox.set_active((bool)value);
		}
    }
    
    public bool no_upscaling
	{
        get { 
			return chkNoUpScale.active; 
		}
        set { 
			chkNoUpScale.set_active((bool)value);
		}
    }
    
    public string frame_rate_num
	{
        owned get { 
			return spinFPSNum.get_value().to_string(); 
		}
        set { 
			spinFPSNum.set_value(double.parse(value));
		}
    }

    public string frame_rate_denom
	{
        owned get { 
			return spinFPSDenom.get_value().to_string(); 
		}
        set { 
			spinFPSDenom.set_value(double.parse(value));
		}
    }
    
    public string acodec
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbACodec,1,"mp3lame");
		}
        set { 
			Utility.Combo_SelectValue(cmbACodec,1,value);
		}
    }
    
    public string audio_mode
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbAudioMode,1,"vbr");
		}
        set { 
			Utility.Combo_SelectValue(cmbAudioMode, 1, value);
		}
    }
    
    public string audio_opus_optimize
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbOpusOptimize,1,"music");
		}
        set { 
			Utility.Combo_SelectValue(cmbOpusOptimize, 1, value);
		}
    }
    
    public string audio_bitrate
	{
        owned get { 
			return spinAudioBitrate.get_value().to_string(); 
		}
        set { 
			spinAudioBitrate.set_value(double.parse(value));
		}
    }
    
    public string audio_quality
	{
        owned get { 
			return spinAudioQuality.get_value().to_string(); 
		}
        set { 
			spinAudioQuality.set_value(double.parse(value));
		}
    }
    
    public string audio_channels
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbAudioChannels,1,"disable");
		}
        set { 
			Utility.Combo_SelectValue(cmbAudioChannels, 1, value);
		}
    }
    
    public string audio_sampling
	{
        owned get { 
			return Utility.Combo_GetSelectedValue(cmbAudioSampleRate,1,"disable");
		}
        set { 
			Utility.Combo_SelectValue(cmbAudioSampleRate, 1, value);
		}
    }
}
