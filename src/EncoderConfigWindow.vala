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

	private Gtk.Paned pane;
	private Gtk.Box vbox_main;
	private Gtk.StackSidebar sidebar;
	private Gtk.Stack stack;

	// grids
	private Gtk.Grid grid_video;
	private Gtk.Grid grid_audio;
	private Gtk.Grid grid_subs;
	private Gtk.Grid grid_vf;
	private Gtk.Grid grid_af;
	private Gtk.Grid grid_tags;

	//preset
	private Gtk.Entry txt_preset_name;
	private Gtk.Entry txt_author_name;
	private Gtk.Entry txt_author_email;
	private Gtk.Entry txt_preset_version;

	//file format
	private Gtk.ComboBox cmb_format;
	private Gtk.ComboBox cmb_ext;
	private Gtk.Image img_file_format;
	
	//video encoder
	private Gtk.ComboBox cmb_vcodec;
	private Gtk.Label lbl_vmessage;
	private Gtk.Label lbl_vmode;
	private Gtk.ComboBox cmb_vmode;
	private Gtk.Label lbl_vbitrate;
	private Gtk.SpinButton spin_vbitrate;
	private Gtk.ComboBox cmb_x264_preset;
	private Gtk.Label lbl_x264_preset;
	private Gtk.Label lbl_x264_profile;
	private Gtk.ComboBox cmb_x264_profile;
	private Gtk.Label lbl_vquality;
	private Gtk.SpinButton spin_vquality;
	private Gtk.ComboBox cmb_vpx_speed;
	private Gtk.Label lbl_vpx_speed;
	private Gtk.Scale scale_vpx_speed;
	private Gtk.Label lvl_voptions;
	private Gtk.TextView txt_voptions;
	private Gtk.Image img_video_format;
	
	// video encoder
	private Gtk.Label lbl_frame_size;
	private Gtk.ComboBox cmb_frame_size;
	private Gtk.SpinButton spin_width;
	private Gtk.SpinButton spin_height;
	private Gtk.CheckButton cmb_no_upscale;
	private Gtk.CheckButton chk_box_fit;
	private Gtk.ComboBox cmb_fps;
	private Gtk.SpinButton spin_fps_num;
	private Gtk.SpinButton spin_fps_denom;
	private Gtk.ComboBox cmb_resize_method;

	// audio encoder
	private Gtk.Label lbl_acodec;
	private Gtk.ComboBox cmb_acodec;
	private Gtk.Label lbl_acodec_msg;
	private Gtk.Label lbl_amode;
	private Gtk.ComboBox cmb_amode;
	private Gtk.Label lbl_abitrate;
	private Gtk.SpinButton spin_abitrate;
	private Gtk.Label lbl_aquality;
	private Gtk.SpinButton spin_aquality;
	private Gtk.Label lbl_opus_optimize;
	private Gtk.ComboBox cmb_opus_optimize;
	private Gtk.Label lbl_aac_profile;
	private Gtk.ComboBox cmb_aac_profile;
	private Gtk.Image img_audio_format;

	// audio filters
	private Gtk.Label lbl_sampling;
	private Gtk.ComboBox cmb_sampling;
	private Gtk.Label lblAudioChannels;
	private Gtk.ComboBox cmb_channels;

	// sox
	private Gtk.Switch switch_sox;
	private Gtk.Box vboxSoxOuter;
	private Gtk.Label lbl_sox_header;
	private Gtk.Label lbl_bass;
	private Gtk.Scale scale_bass;
	private Gtk.Label lbl_treble;
	private Gtk.Scale scale_treble;
	private Gtk.Label lbl_pitch;
	private Gtk.Scale scale_pitch;
	private Gtk.Label lbl_tempo;
	private Gtk.Scale scale_tempo;
	private Gtk.Label lbl_fade_in;
	private Gtk.SpinButton spin_fade_in;
	private Gtk.Label lbl_fade_out;
	private Gtk.SpinButton spin_fade_out;
	private Gtk.ComboBox cmb_fade_type;
	private Gtk.CheckButton chk_normalize;
	private Gtk.CheckButton chk_earwax;
	private string sox_options = "";
	
	// subs
	private Gtk.Label lbl_sub_mode;
	private Gtk.ComboBox cmb_sub_mode;
	private Gtk.Label lbl_scodec_msg;

	// tags
	private Gtk.CheckButton chk_copy_tags;

	private uint tmr_init = 0;

	// actions
	private Gtk.Button btn_save;
	private Gtk.Button btn_cancel;

	public EncoderConfigWindow.from_preset(Gtk.Window parent, string _folder, string _name, bool _is_new){
		set_transient_for(parent);
		set_modal(true);
		
		Folder = _folder;
		Name = _name;
		IsNew = _is_new;
		
		init_ui();
	}
	
	private void init_ui() {
		title = _("Preset");
		set_default_size (550, 550);

		window_position = WindowPosition.CENTER_ON_PARENT;
		destroy_with_parent = true;
		skip_taskbar_hint = true;
		modal = true;
		icon = get_app_icon(16);

		this.delete_event.connect(on_delete_event);

		//get content area
		vbox_main = get_content_area();

		// add widgets ---------------------------------------------

		/* Note: Setting tab button padding to 0 causes problems with some GTK themes like Mint-X */
		
		init_ui_navpane ();

		init_ui_general();

		init_ui_audio();
		
		init_ui_video();

		init_ui_audio_filters();

		init_ui_video_filters();

		init_ui_sox();
		
		init_ui_subtitles();

		init_ui_tags();

		// Actions ----------------------------------------------

		var vbox = get_action_area();
		vbox.margin = 6;
		
        //btn_save
        btn_save = (Button) add_button ("gtk-save", Gtk.ResponseType.ACCEPT);
        btn_save.clicked.connect (btn_save_clicked);

        //btn_cancel
        btn_cancel = (Button) add_button ("gtk-cancel", Gtk.ResponseType.CANCEL);
        btn_cancel.clicked.connect (() => { destroy(); });

		show_all();

        tmr_init = Timeout.add(100, init_delayed);
	}

	private void init_ui_navpane(){
		pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		//pane.margin = 6;
		vbox_main.add(pane);

		sidebar = new Gtk.StackSidebar();
		sidebar.set_size_request(120,-1);
		pane.pack1(sidebar, false, false); //resize, shrink

		stack = new Gtk.Stack();
		stack.set_transition_duration (200);
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_UP_DOWN);
		pane.pack2(stack, true, true); //resize, shrink

		pane.wide_handle = false;
		
		sidebar.set_stack(stack);
	}

	private void init_ui_general(){

		var grid = new Grid();
		grid.set_column_spacing (12);
		grid.set_row_spacing (6);
		grid.margin = 12;
		//grid.margin_right = 24;

		stack.add_titled (grid, "general", _("General"));
		
		int row = -1;
		Gtk.ListStore model;
		TreeIter iter;

		//lblHeaderFileFormat
		var label = new Gtk.Label(_("<b>File Format</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_bottom = 6;
		grid.attach(label,0,++row,3,1);

		// format ---------------------------------------
		
		label = new Gtk.Label(_("Format"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);

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

		var combo = new ComboBox.with_model(model);
		var textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        combo.changed.connect(cmbFileFormat_changed);
        grid.attach(combo,1,row,1,1);
		cmb_format = combo;
		
        // extension ----------------------------
        
		label = new Gtk.Label(_("Extension"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);

		combo = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        grid.attach(combo,1,row,1,1);
		cmb_ext = combo;
		
        // presets ---------------------------------
        
		label = new Gtk.Label(_("<b>Preset</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_top = 6;
		label.margin_bottom = 6;
		grid.attach(label,0,++row,3,1);

        // name ------------------------------------
        
		label = new Gtk.Label(_("Name"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);

		txt_preset_name = new Gtk.Entry();
		txt_preset_name.xalign = (float) 0.0;
		txt_preset_name.text = _("New Preset");
		grid.attach(txt_preset_name,1,row,2,1);

		// version ------------------------------------
		
		label = new Gtk.Label(_("Version"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);

		txt_preset_version = new Gtk.Entry();
		txt_preset_version.xalign = (float) 0.0;
		txt_preset_version.text = "1.0";
		grid.attach(txt_preset_version,1,row,2,1);

        // author --------------------------------------
        
		label = new Gtk.Label(_("Author"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);

		txt_author_name = new Gtk.Entry();
		txt_author_name.xalign = (float) 0.0;
		txt_author_name.text = "";
		grid.attach(txt_author_name,1,row,2,1);

		// email ----------------------------------------
		
		label = new Gtk.Label(_("Email"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);

		txt_author_email = new Gtk.Entry();
		txt_author_email.xalign = (float) 0.0;
		txt_author_email.text = "";
		grid.attach(txt_author_email,1,row,2,1);

		//img_file_format --------------------------------
		
		img_file_format = new Gtk.Image();
		img_file_format.margin_top = 6;
		img_file_format.margin_bottom = 6;
		img_file_format.expand = true;
        grid.attach(img_file_format,0,++row,3,1);
	}
	
	private void init_ui_audio(){
		
        var grid = new Grid();
        grid.set_column_spacing (12);
        grid.set_row_spacing (6);
        grid.margin = 12;
        grid.visible = false;
		grid_audio = grid;

		stack.add_titled (grid_audio, "audio", _("Audio"));
		
		int row = -1;
		Gtk.ListStore model;
		TreeIter iter;

		//lblHeaderFileFormat
		var label = new Gtk.Label(_("<b>Audio Encoder</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_bottom = 6;
		grid.attach(label,0,++row,3,1);
		
		// format ----------------------------
		
		lbl_acodec = new Gtk.Label(_("Format / Codec"));
		lbl_acodec.xalign = (float) 1.0;
		grid_audio.attach(lbl_acodec,0,++row,1,1);

		//cmb_acodec
		cmb_acodec = new ComboBox();
		var textCell = new CellRendererText();
        cmb_acodec.pack_start(textCell, false);
        cmb_acodec.set_attributes(textCell, "text", 0);
        cmb_acodec.changed.connect(cmb_acodec_changed);
        grid_audio.attach(cmb_acodec,1,row,1,1);

		// message ---------------------------------
		
		lbl_acodec_msg = new Gtk.Label("");
		lbl_acodec_msg.xalign = (float) 0.0;
		lbl_acodec_msg.wrap = true;
		lbl_acodec_msg.wrap_mode = Pango.WrapMode.WORD;
		lbl_acodec_msg.use_markup = true;
		grid_audio.attach(lbl_acodec_msg,0,++row,3,1);
		
		// mode ------------------------------------
		
		lbl_amode = new Gtk.Label(_("Encoding Mode"));
		lbl_amode.xalign = (float) 1.0;
		grid_audio.attach(lbl_amode,0,++row,1,1);

		cmb_amode = new ComboBox();
		textCell = new CellRendererText();
        cmb_amode.pack_start(textCell, false);
        cmb_amode.set_attributes(textCell, "text", 0);
        cmb_amode.changed.connect(cmb_amode_changed);
        grid_audio.attach(cmb_amode,1,row,1,1);
		
		// bitrate ----------------------------------------
		
		lbl_abitrate = new Gtk.Label(_("Bitrate (kbps)"));
		lbl_abitrate.xalign = (float) 1.0;
		grid_audio.attach(lbl_abitrate,0,++row,1,1);

		//spin_abitrate 
		Gtk.Adjustment adjAudioBitrate = new Gtk.Adjustment(128, 32, 320, 1, 1, 0);
		spin_abitrate  = new Gtk.SpinButton (adjAudioBitrate, 1, 0);
		spin_abitrate.xalign = (float) 0.5;
		grid_audio.attach(spin_abitrate,1,row,1,1);

		spin_abitrate.notify["sensitive"].connect(()=>{ lbl_abitrate.sensitive = spin_abitrate.sensitive; });
		
		// quality -------------------------------------------
		
		lbl_aquality = new Gtk.Label(_("Quality"));
		lbl_aquality.xalign = (float) 1.0;
		grid_audio.attach(lbl_aquality,0,++row,1,1);

		//spin_aquality
		Gtk.Adjustment adjAudioQuality = new Gtk.Adjustment(4, 0, 9, 1, 1, 0);
		spin_aquality = new Gtk.SpinButton (adjAudioQuality, 1, 0);
		spin_aquality.xalign = (float) 0.5;
		grid_audio.attach(spin_aquality,1,row,1,1);

		spin_aquality.notify["sensitive"].connect(()=>{ lbl_aquality.sensitive = spin_aquality.sensitive; });

		// opus optimize -------------------------------------------
		
		lbl_opus_optimize = new Gtk.Label(_("Optimization"));
		lbl_opus_optimize.xalign = (float) 1.0;
		grid_audio.attach(lbl_opus_optimize,0,++row,1,1);

		//cmb_opus_optimize
		cmb_opus_optimize = new ComboBox();
		textCell = new CellRendererText();
        cmb_opus_optimize.pack_start(textCell, false);
        cmb_opus_optimize.set_attributes(textCell, "text", 0);
        grid_audio.attach(cmb_opus_optimize,1,row,1,1);

        //populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("None"),1,"none");
		model.append (out iter);
		model.set (iter,0,_("Speech"),1,"speech");
		model.append (out iter);
		model.set (iter,0,_("Music"),1,"music");
		cmb_opus_optimize.set_model(model);

		// AAC profile ------------------------------------
		
		lbl_aac_profile = new Gtk.Label(_("Profile"));
		lbl_aac_profile.xalign = (float) 1.0;
		//lbl_aac_profile.no_show_all = true;
		grid_audio.attach(lbl_aac_profile,0,++row,1,1);

		//cmb_aac_profile
		cmb_aac_profile = new ComboBox();
		textCell = new CellRendererText();
        cmb_aac_profile.pack_start(textCell, false);
        cmb_aac_profile.set_attributes(textCell, "text", 0);
        //cmb_aac_profile.no_show_all = true;
        //cmb_aac_profile.set_size_request(150,-1);
        grid_audio.attach(cmb_aac_profile,1,row,1,1);
		//sizegroup.add_widget(cmb_aac_profile);
		
		//tooltip
		string tt = _("<b>AAC-LC (Recommended)</b>\nMPEG-2 Low-complexity (LC) combined with MPEG-4 Perceptual Noise Substitution (PNS)\n\n");
		tt += _("<b>HE-AAC</b>\nAAC-LC + SBR (Spectral Band Replication)\n\n");
		tt += _("<b>HE-AAC v2</b>\nAAC-LC + SBR + PS (Parametric Stereo)\n\n");
		tt += _("<b>AAC-LD</b>\nLow Delay Profile for real-time communication\n\n");
		tt += _("<b>AAC-ELD</b>\nEnhanced Low Delay Profile for real-time communication\n\n");
		tt += _("<b>AAC-ELD</b>\nEnhanced Low Delay Profile for real-time communication\n\n");
		tt += _("<b>Note:</b>\nHE-AAC and HE-AACv2 are used for low-bitrate encoding while HE-LD and HE-ELD are used for real-time communication. HE-AAC is suitable for bit rates between 48 to 64 kbps (stereo) while HE-AACv2 is suitable for bit rates as low as 32 kbps.");
		cmb_aac_profile.set_tooltip_markup(tt);
		lbl_aac_profile.set_tooltip_markup(tt);
		
        //populate
		cmb_aac_profile_refresh();
		
		//img_audio_format
		img_audio_format = new Gtk.Image();
		img_audio_format.margin_top = 6;
		img_audio_format.margin_bottom = 6;
		img_audio_format.expand = true;
        grid_audio.attach(img_audio_format,0,++row,3,1);
	}

	private void init_ui_audio_filters(){
		
        var grid = new Grid();
        grid.set_column_spacing (12);
        grid.set_row_spacing (6);
        grid.margin = 12;
        grid.visible = false;
		grid_af = grid;

		stack.add_titled (grid_af, "af", _("Filters (A)"));
		
		int row = -1;
		int col;

		// resample -----------------------------------------
		
		var label = new Gtk.Label(_("<b>Resample</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_top = 6;
		label.margin_bottom = 6;
		grid.attach(label,col=0,++row,2,1);

		//lbl_sampling
		lbl_sampling = new Gtk.Label(_("Sampling Rate (Hz)"));
		lbl_sampling.xalign = (float) 1.0;
		lbl_sampling.margin_left = 12;
		grid.attach(lbl_sampling,col=0,++row,1,1);

		//cmb_sampling
		cmb_sampling = new ComboBox();
		var textCell = new CellRendererText();
        cmb_sampling.pack_start(textCell, false);
        cmb_sampling.set_attributes(textCell, "text", 0);
        grid.attach(cmb_sampling,col+1,row,1,1);

		// channels -----------------------------------------
		
		label = new Gtk.Label(_("<b>Channels</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_top = 6;
		label.margin_bottom = 6;
		grid.attach(label,col=0,++row,2,1);
		
		//lblAudioChannels
		lblAudioChannels = new Gtk.Label(_("Channels"));
		lblAudioChannels.xalign = (float) 1.0;
		grid.attach(lblAudioChannels,col=0,++row,1,1);

		//cmb_channels
		cmb_channels = new ComboBox();
		textCell = new CellRendererText();
        cmb_channels.pack_start(textCell, false);
        cmb_channels.set_attributes(textCell, "text", 0);
        grid.attach(cmb_channels,col+1,row,1,1);
	}

	private void init_ui_sox(){
		int scaleWidth = 200;
		int sliderMarginBottom = 3;
		int spacing = 6;

        vboxSoxOuter = new Box(Orientation.VERTICAL,spacing);
		vboxSoxOuter.margin = 12;

		stack.add_titled (vboxSoxOuter, "sox", _("SOX"));
		
		// SOX switch ------------------------------------
		
		var hbox = new Box(Orientation.HORIZONTAL,0);
		hbox.margin_bottom = 6;
        vboxSoxOuter.add(hbox);

		//lbl_sox_header
		var label = new Gtk.Label(_("<b>SOX Audio Processing</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.hexpand = true;
		hbox.add(label);
		lbl_sox_header = label;
		
		//switch_sox
        switch_sox = new Gtk.Switch();
        switch_sox.set_size_request(100,-1);
        hbox.add(switch_sox);

        //vboxSox
        Box vboxSox = new Box(Orientation.VERTICAL,spacing);
        vboxSoxOuter.add(vboxSox);

        switch_sox.notify["active"].connect(()=>{
			vboxSox.sensitive = switch_sox.active;

			App.Encoders["sox"].CheckAvailability();
			if (!App.Encoders["sox"].IsAvailable){
				if (switch_sox.active){
					gtk_messagebox(_("Sox Not Installed"), _("The Sox utility was not found on your system") + "\n" + _("Please install the 'sox' package on your system to use this feature"), this, true);
					switch_sox.active = false;
				}
			}
		});

		switch_sox.active = false;
		vboxSox.sensitive = switch_sox.active;

		var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
		
		// adjustments header --------------------------------------
		
		label = new Gtk.Label(_("<b>Adjustments:</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.hexpand = true;
		label.margin_top = 6;
		label.margin_bottom = 6;
		vboxSox.add(label);

		// bass ---------------------------------------------------
		
		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);

		var tt = _("Boost or cut the bass (lower) frequencies of the audio.");

		label = new Gtk.Label(_("Bass") + ": ");
		label.xalign = (float) 1.0;
		label.margin_left = 6;
		label.set_tooltip_text(tt);
		hbox.pack_start(label,false,false,0);
		lbl_bass = label;

		// scale_bass
		var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -20, 20, 1);
		scale.adjustment.value = 0;
		scale.has_origin = false;
		scale.value_pos = PositionType.RIGHT;
		scale.set_size_request(scaleWidth,-1);
		scale.margin_bottom = sliderMarginBottom;
		hbox.pack_start(scale,true,true,0);
		scale_bass = scale;
		
		sizegroup.add_widget(lbl_bass);
		
		scale_bass.format_value.connect((val)=>{
			return "%.0f ".printf(val);
		});

		// add sox preview image ---------------
		
		/*var s = "";
		if (sox_bass != "0"){
			s += " bass " + sox_bass;
		}
		add_sox_preview_image(hbox, s);*/
		
		// Treble ---------------------------------------------------
		
		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);

		tt = _("Boost or cut the treble (upper) frequencies of the audio.");

		label = new Gtk.Label(_("Treble") + ": ");
		label.xalign = (float) 1.0;
		label.margin_left = 6;
		label.set_tooltip_text(tt);
		hbox.pack_start(label,false,false,0);
		lbl_treble = label;

		// scale_treble
		scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -20, 20, 1);
		scale.adjustment.value = 0;
		scale.has_origin = false;
		scale.value_pos = PositionType.RIGHT;
		scale.set_size_request(scaleWidth,-1);
		scale.margin_bottom = sliderMarginBottom;
		hbox.pack_start(scale,true,true,0);
		scale_treble = scale;
		
		sizegroup.add_widget(lbl_treble);
		
		scale_treble.format_value.connect((val)=>{
			return "%.0f ".printf(val);
		});

		// add sox preview image ---------------------
		
		/*s = "";
		if (sox_treble != "0"){
			s += " treble " + sox_treble;
		}
		add_sox_preview_image(hbox, s);*/
		
		// Pitch --------------------------------------------------
		
		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);

		tt = _("Change audio pitch (shrillness) without changing audio tempo (speed).");

		label = new Gtk.Label(_("Pitch") + ": ");
		label.xalign = (float) 1.0;
		label.margin_left = 6;
		label.set_tooltip_text(tt);
		hbox.pack_start(label,false,false,0);
		lbl_pitch = label;

		// scale_pitch
		scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 500, 1);
		scale.adjustment.value = 100;
		//scale.has_origin = false;
		scale.value_pos = PositionType.RIGHT;
		scale.set_size_request(scaleWidth,-1);
		scale.margin_bottom = sliderMarginBottom;
		hbox.pack_start(scale,true,true,0);
		scale_pitch = scale;
		
		sizegroup.add_widget(lbl_pitch);
		
		scale_pitch.format_value.connect((val)=>{
			return "%.0f%% ".printf(val);
		});

		// add sox preview image ---------------------
		
		/*s = "";
		if (sox_pitch != "1.0"){
			s += " pitch " + sox_pitch;
		}
		add_sox_preview_image(hbox, s);*/
		
		// Tempo --------------------------------------------------
		
		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);

		tt = _("Change audio tempo (speed) without changing audio pitch (shrillness).\n\nWARNING: This will change the duration of the audio track");

		label = new Gtk.Label(_("Tempo") + ": ");
		label.xalign = (float) 1.0;
		label.margin_left = 6;
		label.set_tooltip_text(tt);
		hbox.pack_start(label,false,false,0);
		lbl_tempo = label;

		// scale_tempo
		scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 30, 200, 1);
		scale.adjustment.value = 100;
		//scale.has_origin = false;
		scale.value_pos = PositionType.RIGHT;
		scale.set_size_request(scaleWidth,-1);
		scale.margin_bottom = sliderMarginBottom;
		hbox.pack_start(scale,true,true,0);
		scale_tempo = scale;
		
		sizegroup.add_widget(lbl_tempo);
		
		scale_tempo.format_value.connect((val)=>{
			return "%.0f%% ".printf(val);
		});

		// add sox preview image ---------------------
		
		/*s = "";
		if (sox_tempo != "1.0"){
			s += " tempo " + sox_tempo;
		}
		add_sox_preview_image(hbox, s);*/
		
		// fade header ---------------------------------------------
		
		label = new Gtk.Label(_("<b>Fade:</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.hexpand = true;
		label.margin_top = 6;
		label.margin_bottom = 6;
		vboxSox.add(label);

		sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
		
		// fade in ------------------------------------------------
		
		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);

		label = new Gtk.Label(_("Fade In (sec)"));
		label.xalign = (float) 1.0;
		label.margin_left = 6;
		hbox.pack_start(label,false,false,0);
		lbl_fade_in = label;
		
		sizegroup.add_widget(label);
		
		// spin_fade_in
		Gtk.Adjustment adjFadeIn = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		var spin = new Gtk.SpinButton (adjFadeIn, 1, 0);
		spin.xalign = (float) 0.5;
		hbox.pack_start(spin,false,false,0);
		spin_fade_in = spin;
		
		// fade out -----------------------------------------------
		
		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);

		label = new Gtk.Label(_("Fade Out (sec)"));
		label.xalign = (float) 1.0;
		label.margin_left = 6;
		hbox.pack_start(label,false,false,0);
		lbl_fade_out = label;
		
		sizegroup.add_widget(label);
		
		// spin_fade_out
		Gtk.Adjustment adjFadeOut = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adjFadeOut, 1, 0);
		spin.xalign = (float) 0.5;
		hbox.pack_start(spin,false,false,0);
		spin_fade_out = spin;
		
		// fade type ------------------------------------------------
		
		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);

		label = new Gtk.Label(_("Fade Type"));
		label.xalign = (float) 1.0;
		label.margin_left = 6;
		hbox.pack_start(label,false,false,0);

		sizegroup.add_widget(label);
		
		// cmb_fade_type
		var combo = new ComboBox();
		var textCell = new CellRendererText();
        combo.pack_start(textCell, false);
        combo.set_attributes(textCell, "text", 0);
		hbox.pack_start(combo,false,false,0);
		cmb_fade_type = combo;

		TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
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
		combo.set_model(model);

		// add sox preview image ---------------------
		
		/*s = "";
		if ((sox_fade_in != "0") || (sox_fade_out != "0")){
			s += " fade " + sox_fade_type + " " + sox_fade_in;
		}
		add_sox_preview_image(hbox, s);*/
		
		// header other ----------------------------------------
		
		label = new Gtk.Label(_("<b>Other Effects:</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.hexpand = true;
		label.margin_top = 6;
		label.margin_bottom = 6;
		vboxSox.add(label);

		// Normalize -------------------------------------------------

		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);
        
		tt = _("Maximize the volume level (loudness)");

		//chk_normalize
		var chk = new CheckButton.with_label(_("Maximize Volume Level (Normalize)"));
		chk.active = false;
		chk.margin_left = 6;
		chk.set_tooltip_text(tt);
		hbox.add(chk);
		chk_normalize = chk;

		// add sox preview image --------
		
		/*s = "";
		s += " norm";
		add_sox_preview_image(hbox, s);*/
		
		// ear wax --------------------------------------------------

		hbox = new Box(Orientation.HORIZONTAL,spacing);
        vboxSox.add(hbox);
        
		tt = _("Makes audio easier to listen to on headphones. Adds 'cues' to the audio so that when listened to on headphones the stereo image is moved from inside your head (standard for headphones) to outside and in front of the listener (standard for speakers).");

		//chk_earwax
		chk = new CheckButton.with_label(_("Adjust Stereo for Headphones"));
		chk.active = false;
		chk.margin_left = 6;
		chk.set_tooltip_text(tt);
		hbox.add(chk);
		chk_earwax = chk;

		// add sox preview image --------
		
		/*s = "";
		s += " earwax";
		add_sox_preview_image(hbox, s);*/
		
		// link ---------------------------------------
		
		var link = new LinkButton.with_label ("http://sox.sourceforge.net/", "SOund eXchange - http://sox.sourceforge.net/");
		link.xalign = (float) 0.0;
		link.valign = Align.END;
		link.activate_link.connect(()=>{ return exo_open_url(link.uri); });
        vboxSoxOuter.pack_end(link,true,true,0);
	}
	
	/*private void show_popover_audio(Gtk.Image img, string sox_options){
		var pop = new Gtk.Popover(img);
		pop.modal = true;
	
		var vbox = new Box(Orientation.VERTICAL,6);
		vbox.margin = 6;
		pop.add(vbox);

		var label = new Gtk.Label(_("File to preview:"));
		label.xalign = (float) 0.0;
		vbox.add(label);

		var combo = new ComboBox();
		var textCell = new CellRendererText();
		textCell.ellipsize = Pango.EllipsizeMode.END;
		textCell.max_width_chars = 40;
		combo.pack_start( textCell, false );
		combo.set_attributes( textCell, "text", 0 );
		vbox.add(combo);

		TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (MediaFile));
		foreach(MediaFile mf in App.InputFiles){
			model.append (out iter);
			model.set (iter, 0, mf.Name, 1, mf);
		}

		combo.model = model;
		combo.active = 0;
		
		var hbox = new Box(Orientation.HORIZONTAL,6);
		hbox.homogeneous = true;
		hbox.hexpand = true;
		vbox.add(hbox);
		
		var btn = new Gtk.Button.with_label("Preview Audio");
		btn.sensitive = (App.InputFiles.size > 0);
		hbox.add(btn);

		btn.clicked.connect(()=>{
			var mf = App.InputFiles[combo.active];
			App.play_audio(mf, sox_options);
		});
		
		btn = new Gtk.Button.with_label("Play Original");
		btn.sensitive = (App.InputFiles.size > 0);
		hbox.add(btn);
		
		btn.clicked.connect(()=>{
			var mf = App.InputFiles[combo.active];
			mf.play_file(true, false);
		});
		
		pop.show_all();
	}

	private void add_sox_preview_image(Gtk.Box hbox, string sox_options){
		var img = new Gtk.Image();
		img.set_from_file(App.SharedImagesFolder + "/media-playback-start.png");
		img.icon_size = 16;

		var eventbox = new Gtk.EventBox();
		eventbox.add(img);
		hbox.pack_start(eventbox,false,false,0);
			
		eventbox.button_press_event.connect((w, event) => {
			if (event.type == Gdk.EventType.BUTTON_PRESS){
				this.sox_options = sox_options;
				//log_msg("sox:" + this.sox_options);
				show_popover_audio(img, sox_options);
			}
			return true;
		});
		
	}
	*/
	
	private void init_ui_video(){
		
		//grid_video
        var grid = new Grid();
        grid.set_column_spacing (12);
        grid.set_row_spacing (6);
        grid.margin = 12;
		grid_video = grid;

		stack.add_titled (grid_video, "video", _("Video"));
		
		int row = -1;
		string tt = "";

		// header ------------------------
		
		var label = new Gtk.Label(_("<b>Video Encoder</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_bottom = 6;
		grid.attach(label,0,++row,3,1);
		
		// format -----------------------
		
		label = new Gtk.Label(_("Format / Codec"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);
		var lbl_vcodec = label;
		
		//cmb_vcodec
		var combo = new ComboBox();
		var textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        combo.changed.connect(cmb_vcodec_changed);
        grid.attach(combo,1,row,1,1);
		cmb_vcodec = combo;
		
		cmb_vcodec.notify["visible"].connect(()=>{
			lbl_vcodec.visible = cmb_vcodec.visible;
		});

		// message -------------------------------------
		
		//lbl_vmessage
		label = new Gtk.Label("");
		label.xalign = (float) 0.0;
		label.wrap = true;
		label.wrap_mode = Pango.WrapMode.WORD;
		label.use_markup = true;
		grid.attach(label,0,++row,4,1);
		lbl_vmessage = label;

		// mode --------------------------------
		
        //lbl_vmode
		lbl_vmode = new Gtk.Label(_("Encoding Mode"));
		lbl_vmode.xalign = (float) 1.0;
		grid.attach(lbl_vmode,0,++row,1,1);

		//cmb_vmode
		cmb_vmode = new ComboBox();
		textCell = new CellRendererText();
        cmb_vmode.pack_start( textCell, false );
        cmb_vmode.set_attributes( textCell, "text", 0 );
        cmb_vmode.changed.connect(cmb_vmode_changed);
        grid.attach(cmb_vmode,1,row,1,1);

		cmb_vmode.notify["visible"].connect(()=>{
			lbl_vmode.visible = cmb_vmode.visible;
		});

		// bitrate ----------------------------
		
        //lbl_vbitrate
		label = new Gtk.Label(_("Bitrate (kbps)"));
		label.xalign = (float) 1.0;
		label.set_tooltip_text ("");
		grid.attach(label,0,++row,1,1);
		lbl_vbitrate = label;
		
		//spin_vbitrate
		var adjustment = new Gtk.Adjustment(22.0, 0.0, 51.0, 0.1, 1.0, 0.0);
		var spin = new Gtk.SpinButton (adjustment, 0.1, 2);
		spin.xalign = (float) 0.5;
		grid.attach(spin,1,row,1,1);
		spin_vbitrate = spin;
		
		spin_vbitrate.notify["visible"].connect(()=>{
			lbl_vbitrate.visible = spin_vbitrate.visible;
		});
		
		spin_vbitrate.notify["sensitive"].connect(()=>{
			lbl_vbitrate.sensitive = spin_vbitrate.sensitive;
		});
		
		tt = _("<b>Compression Vs Quality</b>\nSmaller values give better quality video and larger files");

		// quality ------------------------------------
		
        //lbl_vquality
		label = new Gtk.Label(_("Quality"));
		label.xalign = (float) 1.0;
		label.set_tooltip_markup(tt);
		grid.attach(label,0,++row,1,1);
		lbl_vquality = label;
		
		//spin_vquality
		adjustment = new Gtk.Adjustment(22.0, 0.0, 51.0, 0.1, 1.0, 0.0);
		spin = new Gtk.SpinButton (adjustment, 0.1, 2);
		spin.set_tooltip_markup(tt);
		spin.xalign = (float) 0.5;
		grid.attach(spin,1,row,1,1);
		spin_vquality = spin;
		
		spin_vquality.notify["visible"].connect(()=>{ lbl_vquality.visible = spin_vquality.visible; });
		spin_vquality.notify["sensitive"].connect(()=>{ lbl_vquality.sensitive = spin_vquality.sensitive; });
		
		tt = _("<b>Compression Vs Encoding Speed</b>\nSlower presets give better compression and smaller files\nbut take more time to encode.");

		// preset -------------------------------
		
        //lblPreset
		label = new Gtk.Label(_("Preset"));
		label.xalign = (float) 1.0;
		label.set_tooltip_markup(tt);
		grid.attach(label,0,++row,1,1);
		lbl_x264_preset = label;
		
		//cmb_x264_preset
		combo = new ComboBox();
		textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        combo.set_tooltip_markup(tt);
        grid.attach(combo,1,row,1,1);
		cmb_x264_preset = combo;

		TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
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
		combo.model = model;
		
		cmb_x264_preset.notify["visible"].connect(()=>{
			lbl_x264_preset.visible = cmb_x264_preset.visible;
		});
		
		tt = _("<b>Compression Vs Device Compatibility</b>\n'High' profile gives the best compression.\nChange this to 'Baseline' or 'Main' only if you are encoding\nfor a particular device (mobiles,PMPs,etc) which does not\nsupport the 'High' profile");

		// profile ---------------------------------------
		
		//lblProfile
		label = new Gtk.Label(_("Profile"));
		label.xalign = (float) 1.0;
		label.set_tooltip_markup(tt);
		grid.attach(label,0,++row,1,1);
		lbl_x264_profile = label;
		
		//cmb_x264_profile
		combo = new ComboBox();
		textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        combo.set_tooltip_markup(tt);
        grid.attach(combo,1,row,1,1);
		cmb_x264_profile = combo;
		
		cmb_x264_profile.notify["visible"].connect(()=>{
			lbl_x264_profile.visible = cmb_x264_profile.visible;
		});

		//lbl_vpx_speed
		label = new Gtk.Label(_("Speed"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);
		lbl_vpx_speed = label;
		
		var hbox = new Box (Orientation.HORIZONTAL, 0);
		hbox.homogeneous = false;
		grid.attach(hbox,1,row,2,1);

		//cmb_vpx_speed
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("Best"), 1, "best");
		model.append (out iter);
		model.set (iter, 0, _("Good"), 1, "good");
		model.append (out iter);
		model.set (iter, 0, _("Realtime"), 1, "realtime");
		
		combo = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        hbox.add(combo);
		cmb_vpx_speed = combo;
		
        cmb_vpx_speed.changed.connect(cmb_vpx_speed_changed);

		cmb_vpx_speed.notify["visible"].connect(()=>{
			lbl_vpx_speed.visible = cmb_vpx_speed.visible;
		});
		
        label = new Gtk.Label("    ");
        hbox.add(label);

		//scale_vpx_speed
        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 5, 1);
		scale.adjustment.value = 1;
		scale.has_origin = false;
		scale.hexpand = true;
		scale.value_pos = PositionType.LEFT;
        hbox.add(scale);
		scale_vpx_speed = scale;
		
		tt = _("<b>Additional Options</b>\nThese options will be passed to the encoder\non the command line. Please do not specify\nany options that are already provided by the GUI.");

		//lvl_voptions
		label = new Gtk.Label(_("Extra Options"));
		label.xalign = (float) 0.0;
		label.margin_top = 6;
		label.set_tooltip_markup(tt);
		grid.attach(label,0,++row,3,1);
		lvl_voptions = label;
		
		//txt_voptions
		var textview = new Gtk.TextView();
		TextBuffer buff = new TextBuffer(null);
		textview.buffer = buff;
		textview.editable = true;
		textview.buffer.text = "";
		textview.expand = true;
		textview.set_tooltip_markup(tt);
		textview.set_wrap_mode (Gtk.WrapMode.WORD);
		txt_voptions = textview;
		
		txt_voptions.notify["visible"].connect(()=>{
			lvl_voptions.visible = txt_voptions.visible;
		});
		
		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.set_shadow_type (ShadowType.ETCHED_IN);
		scroll.add (txt_voptions);
		grid.attach(scroll,0,++row,3,1);

		txt_voptions.notify["visible"].connect(()=>{
			scroll.visible = txt_voptions.visible;
		});

		//img_video_format
		img_video_format = new Gtk.Image();
		img_video_format.margin_top = 6;
		img_video_format.margin_bottom = 6;
        grid.attach(img_video_format,0,++row,3,1);

	}

	private void init_ui_video_filters(){
		
		// grid_vf
        var grid = new Grid();
        grid.set_column_spacing (12);
        grid.set_row_spacing (6);
        grid.margin = 12;
        grid_vf = grid;

        stack.add_titled (grid_vf, "vf", _("Filters (V)"));

		int row = -1;
		string tt = "";
		Gtk.ListStore model;
		TreeIter iter;

		// resize header ------------------------------
		
		var label = new Gtk.Label(_("<b>Resize</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_bottom = 6;
		grid.attach(label,0,++row,3,1);
		
		// resolution --------------------------------------
		
		label = new Gtk.Label(_("Resolution"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,++row,1,1);
		lbl_frame_size = label;
		
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

		var combo = new ComboBox.with_model(model);
        grid.attach(combo,1,row,1,1);
		cmb_frame_size = combo;
	
		var textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );

        combo.changed.connect(cmb_frame_size_changed);
        
		tt = _("Set either Width or Height and leave the other as 0.\nIt will be calculated automatically.\n\nSetting both width and height is not recommended\nsince the video may get stretched or squeezed.\n\nEnable the 'Fit-To-Box' option to avoid changes to aspect ratio.");

        // width --------------------------------------
        
		label = new Gtk.Label(_("Width"));
		label.xalign = (float) 1.0;
		label.set_tooltip_markup (tt);
		grid.attach(label,0,++row,1,1);
		var lblWidth = label;

		var adj = new Gtk.Adjustment(0, 0, 999999, 1, 16, 0);
		var spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text (_("Width"));
		grid.attach(spin,1,row,1,1);
		spin_width = spin;

		spin_width.notify["sensitive"].connect(()=>{ lblWidth.sensitive = spin_width.sensitive; });
		
		// height -------------------------------------
		
		label = new Gtk.Label(_("Height"));
		label.xalign = (float) 1.0;
		label.set_tooltip_markup (tt);
		grid.attach(label,0,++row,1,1);
		var lblHeight = label;
		
		adj = new Gtk.Adjustment(480, 0, 999999, 1, 16, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text (_("Height"));
		grid.attach(spin,1,row,1,1);
		spin_height = spin;

		spin_height.notify["sensitive"].connect(()=>{ lblHeight.sensitive = spin_height.sensitive; });
		
		tt = _("The resizing filter affects the sharpness and compressibility of the video.\nFor example, the 'Lanzos' filter gives sharper video but the extra detail\nmakes the video more difficult to compress resulting in slightly bigger files.\nThe 'Bilinear' filter gives smoother video (less detail) and smaller files.");

		// resize method ------------------------------
		
		label = new Gtk.Label(_("Method"));
		label.xalign = (float) 1.0;
		label.margin_left = 12;
		label.set_tooltip_markup(tt);
		grid.attach(label,0,++row,1,1);
		var lbl_resize_method = label;

		combo = new ComboBox();
		textCell = new CellRendererText();
        combo.pack_start(textCell, false);
        combo.set_attributes(textCell, "text", 0);
        combo.changed.connect(cmb_amode_changed);
        combo.set_tooltip_markup(tt);
        grid.attach(combo,1,row,1,1);
		cmb_resize_method = combo;

		cmb_resize_method.notify["sensitive"].connect(()=>{ lbl_resize_method.sensitive = cmb_resize_method.sensitive; });
		cmb_resize_method.notify["visible"].connect(()=>{ lbl_resize_method.visible = cmb_resize_method.visible; });
		
		tt = _("Fits the video in a box of given width and height.");

		// chk_box_fit ---------------------------
		
		chk_box_fit = new CheckButton.with_label(_("Do not stretch or squeeze the video (Fit-To-Box)"));
		chk_box_fit.active = true;
		chk_box_fit.margin_left = 12;
		chk_box_fit.margin_top = 6;
		chk_box_fit.set_tooltip_markup(tt);
		grid.attach(chk_box_fit,0,++row,3,1);

		tt = _("Video will not be resized if it's smaller than the given width and height");

		// cmb_no_upscale ----------------------------
		
		cmb_no_upscale = new CheckButton.with_label(_("No Up-Scaling"));
		cmb_no_upscale.active = true;
		cmb_no_upscale.margin_left = 12;
		cmb_no_upscale.set_tooltip_markup(tt);
		grid.attach(cmb_no_upscale,0,++row,3,1);

		// header label -------------------------------
		
		label = new Gtk.Label(_("<b>Resample</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_top = 6;
		label.margin_bottom = 6;
		grid.attach(label,0,++row,3,1);

		// fps ----------------------------
		
		label = new Gtk.Label(_("Frame Rate"));
		label.xalign = (float) 1.0;
		label.set_tooltip_text (_("Frames/sec"));
		grid.attach(label,0,++row,1,1);

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

		combo = new ComboBox.with_model(model);
		textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        combo.changed.connect(cmbFPS_changed);
        grid.attach(combo,1,row,1,1);
		cmb_fps = combo;
		
		// fps num ----------------------------
		
		label = new Gtk.Label(_("Fps: Frames"));
		label.xalign = (float) 1.0;
		label.set_tooltip_markup (tt);
		grid.attach(label,0,++row,1,1);
		var lblFpsNum = label;
		
		adj = new Gtk.Adjustment(0, 0, 999999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text (_("Numerator"));
		grid.attach(spin,1,row,1,1);
		spin_fps_num = spin;
		
		spin_fps_num.notify["sensitive"].connect(()=>{ lblFpsNum.sensitive = spin_fps_num.sensitive; });
		
		//fps denom ---------------------------------
		
		label = new Gtk.Label(_("Fps: Seconds"));
		label.xalign = (float) 1.0;
		label.set_tooltip_markup (tt);
		grid.attach(label,0,++row,1,1);
		var lblFpsDenom = label;
		
		adj = new Gtk.Adjustment(0, 0, 999999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text (_("Denominator"));
		grid.attach(spin,1,row,1,1);
		spin_fps_denom = spin;
		
		spin_fps_denom.notify["sensitive"].connect(()=>{ lblFpsDenom.sensitive = spin_fps_denom.sensitive; });
	}

	private void init_ui_subtitles(){
		
        // grid_subs
        var grid = new Grid();
        grid.set_column_spacing (6);
        grid.set_row_spacing (6);
        grid.margin = 12;
		grid_subs = grid;

		stack.add_titled (grid_subs, "subs", _("Subtitles"));

		int row = -1;
		
		// header ----------------------------------------------
		
		var label = new Gtk.Label(_("<b>Subtitles</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_bottom = 6;
		grid.attach(label,0,++row,1,1);
		
		var tt = _("<b>Embed</b> - Subtitle files will be combined with the output file.\nThese subtitles can be switched off since they are added as a separate track");
		tt += "\n\n";
		tt += _("<b>Render</b> - Subtitles are rendered/burned on the video.\nThese subtitles cannot be switched off since they become a part of the video");

		// sub mode -----------------------------------------------
		
		var hbox = new Box(Orientation.HORIZONTAL,6);
		grid.attach(hbox,0,++row,2,1);
		
		//lbl_sub_mode
		label = new Gtk.Label(_("Mode"));
		label.xalign = (float) 1.0;
		label.margin_left = 12;
		label.set_tooltip_markup (tt);
		hbox.add(label);
		lbl_sub_mode = label;
		
		//cmb_sub_mode
		var combo = new ComboBox();
		var textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
        combo.changed.connect(cmb_sub_mode_changed);
        combo.set_tooltip_markup (tt);
        hbox.add(combo);
		cmb_sub_mode = combo;
		
        //lbl_scodec_msg
		label = new Gtk.Label(_("Subtitles"));
		label.xalign = (float) 0.0;
		label.margin_top = 6;
		label.margin_bottom = 6;
		label.wrap = true;
		label.wrap_mode = Pango.WrapMode.WORD;
		label.use_markup = true;
		grid.attach(label,0,++row,3,1);
		lbl_scodec_msg = label;
	}

	private void init_ui_tags(){
		
		// add tab page -------------------------
		
		var grid = new Grid();
		grid.set_column_spacing (12);
		grid.set_row_spacing (6);
		grid.margin = 12;
		grid.visible = false;
		grid_tags = grid;

		stack.add_titled (grid_tags, "tags", _("Tags"));
		
		int row = -1;
		int col;

		// resample -----------------------------------------
		
		var label = new Gtk.Label(_("<b>Tags</b>"));
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_top = 6;
		label.margin_bottom = 6;
		grid.attach(label,col=0,++row,2,1);

		// chk_box_fit ---------------------------

		var tt = _("Copy tags (artist, album, etc) from the source file to output file");

		var chk = new CheckButton.with_label(_("Copy tags from source file"));
		chk.active = true;
		chk.margin_left = 12;
		chk.margin_top = 6;
		chk.set_tooltip_markup(tt);
		grid.attach(chk,0,++row,3,1);
		chk_copy_tags = chk;
	}
	
	private bool on_delete_event(Gdk.EventAny event){
		this.delete_event.disconnect(on_delete_event); //disconnect this handler
		btn_save_clicked();
		return false;
	}

	private bool init_delayed() {
		/* any actions that need to run after window has been displayed */
		if (tmr_init > 0) {
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		//Defaults --------------------------------

		cmb_format.set_active(0);
		//cmb_amode.set_active(0);
		//cmb_vmode.set_active(0);
		//cmb_sub_mode.set_active(0);
		cmb_opus_optimize.set_active(0);
		cmb_x264_preset.set_active(3);
		//cmb_x264_profile.set_active(2);
		cmb_vpx_speed.set_active (1);
		cmb_fps.set_active (0);
		cmb_frame_size.set_active (0);
		cmb_fade_type.set_active (0);
		//cmb_resize_method.set_active (2);
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
		cmb_ext.set_model(model);

		switch (format) {
			case "mp4v":
				model.append(out iter);
				model.set(iter, 0, "MP4", 1, ".mp4");
				model.append(out iter);
				model.set(iter, 0, "M4V", 1, ".m4v");
				cmb_ext.set_active(0);
				break;
			case "mp4a":
				model.append(out iter);
				model.set(iter, 0, "MP4", 1, ".mp4");
				model.append(out iter);
				model.set(iter, 0, "M4A", 1, ".m4a");
				cmb_ext.set_active(0);
				break;
			case "ogv":
				model.append(out iter);
				model.set(iter, 0, "OGV", 1, ".ogv");
				model.append(out iter);
				model.set(iter, 0, "OGG", 1, ".ogg");
				cmb_ext.set_active(0);
				break;
			case "ogg":
				model.append(out iter);
				model.set(iter, 0, "OGG", 1, ".ogg");
				model.append(out iter);
				model.set(iter, 0, "OGA", 1, ".oga");
				cmb_ext.set_active(0);
				break;
			default:
				model.append(out iter);
				model.set(iter, 0, format.up(), 1, "." + format);
				cmb_ext.set_active(0);
				break;
		}

		//populate video codecs ---------------------------

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_vcodec.set_model(model);
		
		switch (format) {
			case "mkv":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"H.264 / MPEG-4 AVC (x264)",1,"x264");
				model.append (out iter);
				model.set (iter,0,"H.265 / MPEG-H HEVC (x265)",1,"x265"); //not yet supported
				cmb_vcodec.set_active(1);
				break;
			case "mp4v":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"H.264 / MPEG-4 AVC (x264)",1,"x264");
				model.append (out iter);
				model.set (iter,0,"H.265 / MPEG-H HEVC (x265)",1,"x265");
				cmb_vcodec.set_active(1);
				break;
			case "ogv":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"Theora",1,"theora");
				cmb_vcodec.set_active(1);
				break;
			case "webm":
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"VP8",1,"vp8");
				model.append (out iter);
				model.set (iter,0,"VP9",1,"vp9");
				cmb_vcodec.set_active(1);
				break;
			default:
				model.append (out iter);
				model.set (iter,0,_("Disable Video"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Copy Video"),1,"copy");
				cmb_vcodec.set_active(0);
				break;
		}

		switch (format) {
			case "mkv":
			case "mp4v":
			case "ogv":
			case "webm":
				grid_video.sensitive = true;
				grid_vf.sensitive = true;
				break;
			default:
				grid_video.sensitive = false;
				grid_vf.sensitive = false;
				break;
		}

		//populate audio codecs ---------------------------

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_acodec.set_model(model);

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
				cmb_acodec.set_active(3);
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
				cmb_acodec.set_active(2);
				break;

			case "ogv":
			case "webm":
				model.append (out iter);
				model.set (iter,0,_("Disable Audio"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Copy Audio"),1,"copy");
				model.append (out iter);
				model.set (iter,0,"Opus",1,"opus");
				model.append (out iter);
				model.set (iter,0,"Vorbis",1,"vorbis");
				cmb_acodec.set_active(2);
				break;

			case "ogg":
				model.append (out iter);
				model.set (iter,0,"Vorbis",1,"vorbis");
				cmb_acodec.set_active(0);
				break;

			case "mp3":
				model.append (out iter);
				model.set (iter,0,"MP3 / LAME",1,"mp3lame");
				cmb_acodec.set_active(0);
				break;

			case "mp4a":
				model.append (out iter);
				model.set (iter,0,"AAC / Libav",1,"aac");
				model.append (out iter);
				model.set (iter,0,"AAC / Nero",1,"neroaac");
				model.append (out iter);
				model.set (iter,0,"AAC / Fraunhofer FDK",1,"libfdk_aac");
				cmb_acodec.set_active(0);
				break;

			case "opus":
				model.append (out iter);
				model.set (iter,0,"Opus",1,"opus");
				cmb_acodec.set_active(0);
				break;

			case "ac3":
				model.append (out iter);
				model.set (iter,0,"AC3 / Libav",1,"ac3");
				cmb_acodec.set_active(0);
				break;

			case "flac":
				model.append (out iter);
				model.set (iter,0,"FLAC / Libav",1,"flac");
				cmb_acodec.set_active(0);
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
				cmb_acodec.set_active(1);
				break;
		}

		//populate subtitle options

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_sub_mode.set_model(model);

		switch (format){
			case "mkv":
			case "mp4v":
			case "ogg":
			case "ogv":
				grid_subs.sensitive = true;

				model.append (out iter);
				model.set (iter,0,_("No Subtitles"),1,"disable");
				model.append (out iter);
				model.set (iter,0,_("Embed / Soft Subs"),1,"embed");
				cmb_sub_mode.set_active(1);
				break;

			default:
				grid_subs.sensitive = false;
				break;
		}

		//set logo

		switch (format){
			case "mkv":
				img_file_format.set_from_file(App.SharedImagesFolder + "/matroska.png");
				img_file_format.xalign = (float) 0.5;
				img_file_format.yalign = (float) 1.0;
				break;
			case "opus":
				img_file_format.set_from_file(App.SharedImagesFolder + "/opus.png");
				img_file_format.xalign = (float) 0.5;
				img_file_format.yalign = (float) 1.0;
				break;
			case "webm":
				img_file_format.set_from_file(App.SharedImagesFolder + "/webm.png");
				img_file_format.xalign = (float) 0.5;
				img_file_format.yalign = (float) 1.0;
				break;
			case "ogg":
				img_file_format.set_from_file(App.SharedImagesFolder + "/vorbis.png");
				img_file_format.xalign = (float) 0.5;
				img_file_format.yalign = (float) 1.0;
				break;
			case "ogv":
				img_file_format.set_from_file(App.SharedImagesFolder + "/theora.png");
				img_file_format.xalign = (float) 0.5;
				img_file_format.yalign = (float) 1.0;
				break;
			case "ac3":
			case "flac":
			case "wav":
				img_file_format.set_from_file(App.SharedImagesFolder + "/ffmpeg.svg");
				img_file_format.xalign = (float) 0.5;
				img_file_format.yalign = (float) 1.0;
				break;
			/*case "mp3":
				img_file_format.set_from_file(App.SharedImagesFolder + "/lame.png");
				img_file_format.xalign = (float) 0.5;
				img_file_format.yalign = (float) 1.0;
				break;*/
			default:
				img_file_format.clear();
				break;
		}
	}

	private void cmb_acodec_changed(){
		Gtk.ListStore model;
		TreeIter iter;

		lbl_amode.visible = false;
		cmb_amode.visible = false;
		lbl_abitrate.visible = false;
		spin_abitrate.visible = false;
		lbl_aquality.visible = false;
		spin_aquality.visible = false;
		lbl_opus_optimize.visible = false;
		cmb_opus_optimize.visible = false;
		lbl_aac_profile.visible = false;
		cmb_aac_profile.visible = false;

		//show message
		switch (acodec){
			case "copy":
				lbl_acodec_msg.visible = true;
				lbl_acodec_msg.label = _("\n<b>Note:</b>\n\n1. Audio track will be copied directly to the output file without changes.\n\n2. Format of the audio track must be compatible with the selected file format. For example, if the input file contains AAC audio and the selected file format is WEBM, then encoding will fail - since WEBM does not support AAC audio.\n\n3. Input file can be trimmed only in basic mode (single segment). Selecting multiple segments using advanced mode will not work.");
				break;
			default:
				lbl_acodec_msg.visible = false;
				break;
		}
		
		//show & hide options
		switch (acodec){
			case "opus":
				//All modes require bitrate as input
				lbl_amode.visible = true;
				cmb_amode.visible = true;
				lbl_abitrate.visible = true;
				spin_abitrate.visible = true;
				//lbl_aquality.visible = true;
				//spin_aquality.visible = true;
				lbl_opus_optimize.visible = true;
				cmb_opus_optimize.visible = true;
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
				lbl_amode.visible = true;
				cmb_amode.visible = true;
				lbl_abitrate.visible = true;
				spin_abitrate.visible = true;
				break;
			case "aac":
			case "neroaac":
			case "libfdk_aac":
				lbl_amode.visible = true;
				cmb_amode.visible = true;
				lbl_abitrate.visible = true;
				spin_abitrate.visible = true;
				lbl_aquality.visible = true;
				spin_aquality.visible = true;
				lbl_aac_profile.visible = true;
				cmb_aac_profile.visible = true;
				break;
			case "mp3lame":
			case "vorbis":
				lbl_amode.visible = true;
				cmb_amode.visible = true;
				lbl_abitrate.visible = true;
				spin_abitrate.visible = true;
				lbl_aquality.visible = true;
				spin_aquality.visible = true;
				break;
		}

		//disable options when audio is disabled
		switch (acodec){
			case "disable":
			case "copy":
				grid_af.sensitive = false;
				vboxSoxOuter.sensitive = false;
				break;
			default:
				grid_af.sensitive = true;
				vboxSoxOuter.sensitive = true;
				break;
		}

		//populate encoding modes
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_amode.set_model(model);
			
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
				cmb_amode.set_active(0);

				spin_abitrate.adjustment.configure(128, 32, 320, 1, 1, 0);
				spin_abitrate.set_tooltip_text ("");
				spin_abitrate.digits = 0;

				spin_aquality.adjustment.configure(4, 0, 9, 1, 1, 0);
				spin_aquality.set_tooltip_text ("");
				spin_aquality.digits = 0;

				cmb_amode.sensitive = true;
				spin_abitrate.sensitive = true;
				spin_aquality.sensitive = true;
				cmb_amode_changed();
				break;

			case "aac":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				cmb_amode.set_active(0);

				spin_abitrate.adjustment.configure(96, 8, 400, 1, 1, 0);
				spin_abitrate.set_tooltip_text ("");
				spin_abitrate.digits = 0;

				spin_aquality.adjustment.configure(1.0, 0.0, 2.0, 0.1, 0.1, 0);
				spin_aquality.digits = 1;

				cmb_amode.sensitive = true;
				cmb_amode_changed();
				break;

			case "libfdk_aac":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				cmb_amode.set_active(0);

				spin_abitrate.adjustment.configure(96, 8, 400, 1, 1, 0);
				spin_abitrate.set_tooltip_text ("");
				spin_abitrate.digits = 0;

				spin_aquality.adjustment.configure(3, 1, 5, 1, 1, 0);
				spin_aquality.digits = 1;
				spin_aquality.set_tooltip_text (
"""
1 = ~20-32 kbps/channel
2 = ~32-40 kbps/channel
3 = ~48-56 kbps/channel
4 = ~64-72 kbps/channel
5 = ~96-112 kbps/channel
""");

				cmb_amode.sensitive = true;
				cmb_amode_changed();
				break;
				
			case "neroaac":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Constant Bitrate"),1,"cbr");
				cmb_amode.set_active(0);

				spin_abitrate.adjustment.configure(96, 8, 400, 1, 1, 0);
				spin_abitrate.set_tooltip_text ("");
				spin_abitrate.digits = 0;

				spin_aquality.adjustment.configure(0.5, 0.0, 1.0, 0.1, 0.1, 0);
				spin_aquality.set_tooltip_text (
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
				spin_aquality.digits = 1;

				cmb_amode.sensitive = true;
				cmb_amode_changed();
				break;

			case "opus":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Constant Bitrate"),1,"cbr");
				cmb_amode.set_active(0);

				spin_abitrate.adjustment.configure(128, 6, 512, 1, 1, 0);
				spin_abitrate.set_tooltip_text ("");
				spin_abitrate.digits = 0;

				cmb_amode.sensitive = true;
				cmb_amode_changed();
				break;

			case "vorbis":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				cmb_amode.set_active(0);

				spin_abitrate.adjustment.configure(128, 32, 500, 1, 1, 0);
				spin_abitrate.set_tooltip_text ("");
				spin_abitrate.digits = 0;

				spin_aquality.adjustment.configure(3, -2, 10, 1, 1, 0);
				spin_aquality.set_tooltip_text ("");
				spin_aquality.digits = 1;

				cmb_amode.sensitive = true;
				cmb_amode_changed();
				break;

			case "ac3":
				model.append (out iter);
				model.set (iter,0,_("Fixed Bitrate"),1,"cbr");
				cmb_amode.set_active(0);

				spin_abitrate.adjustment.configure(128, 1, 512, 1, 1, 0);
				spin_abitrate.set_tooltip_text ("");
				spin_abitrate.digits = 0;

				cmb_amode.sensitive = true;
				cmb_amode_changed();
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
				cmb_amode.set_active(0);

				cmb_amode.sensitive = true;
				break;

			default: //disable
				cmb_amode.visible = false;
				spin_abitrate.visible = false;
				spin_aquality.visible = false;
				break;
		}

		//populate special settings
		cmb_aac_profile_refresh();

		//populate sampling rates
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_sampling.set_model(model);
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
				cmb_sampling.set_active(0);
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
				cmb_sampling.set_active(0);
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
				cmb_sampling.set_active(0);
				break;

			default:
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				cmb_sampling.set_active(0);
				break;
		}

		//populate channels
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_channels.set_model(model);
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
				cmb_channels.set_active(0);
				break;

			default: //mp3lame
				model.append (out iter);
				model.set (iter,0,_("No Change"),1,"disable");
				model.append (out iter);
				model.set (iter,0,"1",1,"1");
				model.append (out iter);
				model.set (iter,0,"2",1,"2");
				cmb_channels.set_active(0);
				break;
		}

		//set logo
		switch (acodec){
			case "opus":
				img_audio_format.set_from_file(App.SharedImagesFolder + "/opus.png");
				img_audio_format.xalign = (float) 0.5;
				img_audio_format.yalign = (float) 1.0;
				break;
			case "mp3lame":
				img_audio_format.set_from_file(App.SharedImagesFolder + "/lame.png");
				img_audio_format.xalign = (float) 0.5;
				img_audio_format.yalign = (float) 1.0;
				break;
			case "vorbis":
				img_audio_format.set_from_file(App.SharedImagesFolder + "/vorbis.png");
				img_audio_format.xalign = (float) 0.5;
				img_audio_format.yalign = (float) 1.0;
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
				img_audio_format.set_from_file(App.SharedImagesFolder + "/ffmpeg.svg");
				img_audio_format.xalign = (float) 0.5;
				img_audio_format.yalign = (float) 1.0;
				break;
			/*case "neroaac":
				img_audio_format.set_from_file(App.SharedImagesFolder + "/aac.png");
				img_audio_format.xalign = (float) 1.0;
				img_audio_format.yalign = (float) 1.0;
				break;*/
			default:
				img_audio_format.clear();
				break;
		}
	}

	private void cmb_amode_changed(){
		switch (audio_mode) {
			case "vbr":
				if (acodec == "opus") {
					spin_abitrate.sensitive = true;
					spin_aquality.sensitive = false;
				}
				else {
					spin_abitrate.sensitive = false;
					spin_aquality.sensitive = true;
				}
				break;
			case "abr":
			case "cbr":
			case "cbr-strict":
				spin_abitrate.sensitive = true;
				spin_aquality.sensitive = false;
				break;
		}
	}

	private void cmb_vcodec_changed(){
		Gtk.ListStore model;
		TreeIter iter;

		//show message
		switch (vcodec){
			case "copy":
				lbl_vmessage.visible = true;
				lbl_vmessage.label = _("\n<b>Note:</b>\n\n1. Video track will be copied to the output file without re-encoding.\n\n2. Format of the video track must be compatible with the selected container. For example, if the input file contains H264 video and the selected file format is WEBM, then encoding will fail (since WEBM does not support H264).\n\n3. If you are trimming the input file then select the basic mode (single segment). Selecting multiple segments in advanced mode will not work.");
				break;
			default:
				lbl_vmessage.visible = false;
				break;
		}

		//disable options when video is disabled
		switch (vcodec){
			case "disable":
			case "copy":
				grid_vf.sensitive = false;
				break;
			default:
				grid_vf.sensitive = true;
				break;
		}
		
		//show x264 options
		switch (vcodec){
			case "x264":
			case "x265":
				cmb_x264_preset.visible = true;
				cmb_x264_profile.visible = true;
				break;
			default:
				cmb_x264_preset.visible = false;
				cmb_x264_profile.visible = false;
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
				cmb_x264_profile.set_model(model);
				cmb_x264_profile.set_active(2);
				break;

			case "x265":
				model = new Gtk.ListStore (2, typeof (string), typeof (string));
				model.append (out iter);
				model.set (iter, 0, "None", 1, "");
				model.append (out iter);
				model.set (iter, 0, "Main", 1, "main");
				model.append (out iter);
				model.set (iter, 0, "Main10", 1, "main10");
				cmb_x264_profile.set_model(model);
				cmb_x264_profile.set_active(0);
				break;
		}

		//show vp8 options
		switch (vcodec){
			case "vp8":
			case "vp9":
				cmb_vpx_speed.visible = true;
				scale_vpx_speed.visible = true;
				scale_vpx_speed.adjustment.value = 1;

				lbl_vpx_speed.set_tooltip_markup("");
				string tt = _("<b>Quality Vs Encoding Speed</b>\n\n<b>Best:</b> Best quality, slower\n<b>Good:</b> Good quality, faster\n<b>Realtime:</b> Fastest");
				cmb_vpx_speed.set_tooltip_markup(tt);
				tt = _("<b>Quality Vs Encoding Speed</b>\n\nSmaller values = Better quality, slower\nLarger value = Lower quality, faster\n");
				scale_vpx_speed.set_tooltip_markup(tt);
				break;

			default:
				cmb_vpx_speed.visible = false;
				scale_vpx_speed.visible = false;

				string tt = _("<b>Quality Vs Encoding Speed</b>\nHigher values speed-up encoding at the expense of quality.\nLower values improve quality at the expense of encoding speed.");
				lbl_vpx_speed.set_tooltip_markup(tt);
				break;
		}

		//populate encoding modes
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_vmode.set_model(model);

		switch (vcodec){
			case "x264":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate / CRF"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate (2-pass)"),1,"2pass");
				cmb_vmode.set_active(0);

				spin_vbitrate.adjustment.configure(800, 1, 10000000, 1, 1, 0);
				spin_vbitrate.set_tooltip_text ("");
				spin_vbitrate.digits = 0;

				spin_vquality.adjustment.configure(23.0, 0, 51, 1, 1, 0);
				spin_vquality.set_tooltip_text ("");
				spin_vquality.digits = 1;

				cmb_vmode.visible = true;
				spin_vbitrate.visible = true;
				spin_vquality.visible = true;
				txt_voptions.visible = true;
				
				cmb_vmode_changed();
				break;

			case "x265":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate / CRF"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate (2-pass)"),1,"2pass");
				cmb_vmode.set_active(0);

				spin_vbitrate.adjustment.configure(800, 1, 10000000, 1, 1, 0);
				spin_vbitrate.set_tooltip_text ("");
				spin_vbitrate.digits = 0;

				spin_vquality.adjustment.configure(28.0, 0, 51, 1, 1, 0);
				spin_vquality.set_tooltip_text ("");
				spin_vquality.digits = 1;

				cmb_vmode.visible = true;
				spin_vbitrate.visible = true;
				spin_vquality.visible = true;
				txt_voptions.visible = true;
				
				cmb_vmode_changed();
				break;

			case "theora":
				model.append (out iter);
				model.set (iter,0,_("Variable Bitrate"),1,"vbr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate"),1,"abr");
				model.append (out iter);
				model.set (iter,0,_("Average Bitrate (2-pass)"),1,"2pass");
				cmb_vmode.set_active(0);

				spin_vbitrate.adjustment.configure(800, 1, 10000000, 1, 1, 0);
				spin_vbitrate.set_tooltip_text ("");
				spin_vbitrate.digits = 0;

				spin_vquality.adjustment.configure(6, 0, 10, 1, 1, 0);
				spin_vquality.set_tooltip_text ("");
				spin_vquality.digits = 1;

				cmb_vmode.visible = true;
				spin_vbitrate.visible = true;
				spin_vquality.visible = true;
				txt_voptions.visible = true;
				cmb_vmode_changed();
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
				cmb_vmode.set_active(0);

				spin_vbitrate.adjustment.configure(800, 1, 1000000000, 1, 1, 0);
				spin_vbitrate.set_tooltip_text ("");
				spin_vbitrate.digits = 0;

				/*spin_vquality.adjustment.configure(-1, -1, 63, 1, 1, 0);
				spin_vquality.set_tooltip_text ("");
				spin_vquality.digits = 0;*/

				cmb_vmode.visible = true;
				spin_vbitrate.visible = true;
				spin_vquality.visible = false;
				txt_voptions.visible = true;
				cmb_vmode_changed();
				break;

			default: //disable
				cmb_vmode.visible = false;
				spin_vbitrate.visible = false;
				spin_vquality.visible = false;
				txt_voptions.visible = false;
				break;
		}

		//populate resize methods
        model = new Gtk.ListStore (2, typeof (string), typeof (string));
		cmb_resize_method.set_model(model);

		switch (vcodec){
			case "x264":
			case "x265":
				cmb_resize_method.visible = true;
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
				cmb_resize_method.set_active(2);
				break;

			default:
				cmb_resize_method.visible = false;
				break;

		}

		//set logo
		switch (vcodec){
			case "x264":
				img_video_format.set_from_file(App.SharedImagesFolder + "/x264.png");
				img_video_format.xalign = (float) 0.5;
				img_video_format.yalign = (float) 1.0;
				break;
			case "x265":
				img_video_format.set_from_file(App.SharedImagesFolder + "/x265.png");
				img_video_format.xalign = (float) 0.5;
				img_video_format.yalign = (float) 1.0;
				break;
			case "vp8":
				img_video_format.set_from_file(App.SharedImagesFolder + "/vp8.png");
				img_video_format.xalign = (float) 0.5;
				img_video_format.yalign = (float) 1.0;
				break;
			case "vp9":
				img_video_format.set_from_file(App.SharedImagesFolder + "/vp9.png");
				img_video_format.xalign = (float) 0.5;
				img_video_format.yalign = (float) 1.0;
				break;
			case "theora":
				img_video_format.set_from_file(App.SharedImagesFolder + "/theora.png");
				img_video_format.xalign = (float) 0.5;
				img_video_format.yalign = (float) 1.0;
				break;
			default:
				img_video_format.clear();
				break;
		}
	}

	private void cmb_frame_size_changed(){
		if (gtk_combobox_get_value(cmb_frame_size,1,"disable") == "custom") {
			spin_width.sensitive = true;
			spin_height.sensitive = true;
		}
		else{
			spin_width.sensitive = false;
			spin_height.sensitive = false;
		}

		if (gtk_combobox_get_value(cmb_frame_size,1,"disable") == "disable") {
			cmb_resize_method.sensitive = false;
			chk_box_fit.sensitive = false;
			cmb_no_upscale.sensitive = false;
		}
		else {
			cmb_resize_method.sensitive = true;
			chk_box_fit.sensitive = true;
			cmb_no_upscale.sensitive = true;
		}

		switch (gtk_combobox_get_value(cmb_frame_size,1,"disable")) {
			case "disable":
				spin_width.value = 0;
				spin_height.value = 0;
				break;
			case "custom":
				spin_width.value = 0;
				spin_height.value = 480;
				break;
			case "320p":
				spin_width.value = 0;
				spin_height.value = 320;
				break;
			case "480p":
				spin_width.value = 0;
				spin_height.value = 480;
				break;
			case "720p":
				spin_width.value = 0;
				spin_height.value = 720;
				break;
			case "1080p":
				spin_width.value = 0;
				spin_height.value = 1080;
				break;
		}
	}

	private void cmbFPS_changed(){
		if (gtk_combobox_get_value(cmb_fps,1,"disable") == "custom") {
			spin_fps_num.sensitive = true;
			spin_fps_denom.sensitive = true;
		}
		else{
			spin_fps_num.sensitive = false;
			spin_fps_denom.sensitive = false;
		}

		switch (gtk_combobox_get_value(cmb_fps,1,"disable")) {
			case "disable":
				spin_fps_num.value = 0;
				spin_fps_denom.value = 0;
				break;
			case "custom":
				spin_fps_num.value = 25;
				spin_fps_denom.value = 1;
				break;
			case "25":
				spin_fps_num.value = 25;
				spin_fps_denom.value = 1;
				break;
			case "29.97":
				spin_fps_num.value = 30000;
				spin_fps_denom.value = 1001;
				break;
			case "30":
				spin_fps_num.value = 30;
				spin_fps_denom.value = 1;
				break;
			case "60":
				spin_fps_num.value = 60;
				spin_fps_denom.value = 1;
				break;
		}
	}

	private void cmb_vmode_changed(){
		switch(vcodec){
			case "vp8":
			case "vp9":
				switch (video_mode) {
					case "cq":
						spin_vbitrate.sensitive = false;
						spin_vquality.sensitive = true;
						break;
					case "vbr":
					case "cbr":
					case "2pass":
						spin_vbitrate.sensitive = true;
						spin_vquality.sensitive = false;
						break;
					default:
						spin_vbitrate.sensitive = false;
						spin_vquality.sensitive = false;
						break;
				}
				break;
			default:
				switch (video_mode) {
					case "vbr":
						spin_vbitrate.sensitive = false;
						spin_vquality.sensitive = true;
						break;
					case "abr":
					case "2pass":
						spin_vbitrate.sensitive = true;
						spin_vquality.sensitive = false;
						break;
					default:
						spin_vbitrate.sensitive = false;
						spin_vquality.sensitive = false;
						break;
				}
				break;
		}

	}

	private void cmb_vpx_speed_changed(){
		switch (vpx_deadline) {
			case "best":
				scale_vpx_speed.adjustment.configure(0, 0, 0, 1, 1, 0);
				scale_vpx_speed.sensitive = false;
				break;

			case "realtime":
				scale_vpx_speed.sensitive = true;
				scale_vpx_speed.adjustment.configure(0, 0, 15, 1, 1, 0);
				break;

			case "good":
			default:
				scale_vpx_speed.sensitive = true;
				scale_vpx_speed.adjustment.configure(1, 0, 5, 1, 1, 0);
				break;
		}
	}

	private void cmb_sub_mode_changed(){
		string txt = "";
				
		switch(subtitle_mode){
			case "embed":
				txt += _("\n<b>Note:</b>\n\n1. Supported subtitle file formats:");
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

				txt += _("2. External subtitle files must be present in the same location and start with the same file name.") + "\n\n";

				break;

			default:
				txt = "";
				break;
		}

		lbl_scodec_msg.label = txt;
	}

	private void cmb_aac_profile_refresh(){
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

		cmb_aac_profile.set_model(model);
		cmb_aac_profile.active = 0;
	}
	
	private void btn_save_clicked(){

		if (txt_preset_name.text.length < 1) {
			stack.set_visible_child_name("general");

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
		Main.set_numeric_locale("C");
		
		var config = new Json.Object();
		var general = new Json.Object();
		var video = new Json.Object();
		var audio = new Json.Object();
		var subs = new Json.Object();
		var tags = new Json.Object();

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

		config.set_object_member("tags",tags);
		tags.set_boolean_member("copyTags",copy_tags);

		var filePath = Folder + "/" + txt_preset_name.text + ".json";
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

		Main.set_numeric_locale("");
	}

	public void load_script(){
		Main.set_numeric_locale("C");
		
		var filePath = Folder + "/" + Name + ".json";
		if(file_exists(filePath) == false){ return; }

		txt_preset_name.text = Name;

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

		// tags -----------------------

		if (config.has_member("tags")){
			Json.Object tags = (Json.Object) config.get_object_member("tags");
			copy_tags = tags.get_boolean_member("copyTags");
		}

		Main.set_numeric_locale("");
	}


	public string format{
        owned get {
			return gtk_combobox_get_value(cmb_format,1,"mkv");
		}
        set {
			gtk_combobox_set_value(cmb_format,1,value);
		}
    }

	public string extension{
        owned get {
			return gtk_combobox_get_value(cmb_ext,1,".mkv");
		}
        set {
			gtk_combobox_set_value(cmb_ext,1,value);
		}
    }

    public string author_name{
        owned get {
			return txt_author_name.text;
		}
        set {
			txt_author_name.text = value;
		}
    }

    public string author_email{
        owned get {
			return txt_author_email.text;
		}
        set {
			txt_author_email.text = value;
		}
    }

    public string preset_name{
        owned get {
			return txt_preset_name.text;
		}
        set {
			txt_preset_name.text = value;
		}
    }

    public string preset_version{
        owned get {
			return txt_preset_version.text;
		}
        set {
			txt_preset_version.text = value;
		}
    }

	public string vcodec{
        owned get {
			return gtk_combobox_get_value(cmb_vcodec,1,"x264");
		}
        set {
			gtk_combobox_set_value(cmb_vcodec,1,value);
		}
    }

    public string video_mode{
        owned get {
			return gtk_combobox_get_value(cmb_vmode,1,"vbr");
		}
        set {
			gtk_combobox_set_value(cmb_vmode,1,value);
		}
    }

    public string video_bitrate{
        owned get {
			return spin_vbitrate.get_value().to_string();
		}
        set {
			spin_vbitrate.set_value(double.parse(value));
		}
    }

    public string video_quality{
        owned get {
			return "%.1f".printf(spin_vquality.get_value());
		}
        set {
			spin_vquality.get_adjustment().set_value(double.parse(value));
		}
    }

	public string x264_preset {
        owned get {
			return gtk_combobox_get_value(cmb_x264_preset,1,"medium");
		}
        set {
			gtk_combobox_set_value(cmb_x264_preset,1,value);
		}
    }

    public string x264_profile{
        owned get {
			return gtk_combobox_get_value(cmb_x264_profile,1,"high");
		}
        set {
			gtk_combobox_set_value(cmb_x264_profile, 1, value);
		}
    }

    public string x264_options{
        owned get {
			return txt_voptions.buffer.text;
		}
        set {
			txt_voptions.buffer.text = value;
		}
    }

    public string vpx_deadline{
        owned get {
			return gtk_combobox_get_value(cmb_vpx_speed,1,"good");
		}
        set {
			gtk_combobox_set_value(cmb_vpx_speed,1,value);
		}
    }

    public string vpx_speed{
        owned get {
			return scale_vpx_speed.adjustment.value.to_string();
		}
        set {
			scale_vpx_speed.adjustment.value = int.parse(value);
		}
    }

    public string frame_size{
        owned get {
			return gtk_combobox_get_value(cmb_frame_size,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmb_frame_size, 1, value);
		}
    }

    public string resizing_method{
        owned get {
			return gtk_combobox_get_value(cmb_resize_method,1,"cubic");
		}
        set {
			gtk_combobox_set_value(cmb_resize_method, 1, value);
		}
    }

    public string frame_width{
        owned get {
			return spin_width.get_value().to_string();
		}
        set {
			spin_width.set_value(double.parse(value));
		}
    }

    public string frame_height{
        owned get {
			return spin_height.get_value().to_string();
		}
        set {
			spin_height.set_value(double.parse(value));
		}
    }

	public bool fit_to_box{
        get {
			return chk_box_fit.active;
		}
        set {
			chk_box_fit.set_active((bool)value);
		}
    }

    public bool no_upscaling{
        get {
			return cmb_no_upscale.active;
		}
        set {
			cmb_no_upscale.set_active((bool)value);
		}
    }

    public string frame_rate{
        owned get {
			return gtk_combobox_get_value(cmb_fps,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmb_fps, 1, value);
		}
    }

    public string frame_rate_num{
        owned get {
			return spin_fps_num.get_value().to_string();
		}
        set {
			spin_fps_num.set_value(double.parse(value));
		}
    }

    public string frame_rate_denom{
        owned get {
			return spin_fps_denom.get_value().to_string();
		}
        set {
			spin_fps_denom.set_value(double.parse(value));
		}
    }

    public string acodec{
        owned get {
			return gtk_combobox_get_value(cmb_acodec,1,"mp3lame");
		}
        set {
			gtk_combobox_set_value(cmb_acodec,1,value);
		}
    }

    public string audio_mode{
        owned get {
			return gtk_combobox_get_value(cmb_amode,1,"vbr");
		}
        set {
			gtk_combobox_set_value(cmb_amode, 1, value);
		}
    }

    public string audio_opus_optimize{
        owned get {
			return gtk_combobox_get_value(cmb_opus_optimize,1,"none");
		}
        set {
			gtk_combobox_set_value(cmb_opus_optimize, 1, value);
		}
    }

    public string audio_profile{
        owned get {
			return gtk_combobox_get_value(cmb_aac_profile,1,"auto");
		}
        set {
			gtk_combobox_set_value(cmb_aac_profile, 1, value);
		}
    }

    public string audio_bitrate{
        owned get {
			return spin_abitrate.get_value().to_string();
		}
        set {
			spin_abitrate.set_value(double.parse(value));
		}
    }

    public string audio_quality{
        owned get {
			return "%.1f".printf(spin_aquality.get_value());
		}
        set {
			spin_aquality.set_value(double.parse(value));
		}
    }

    public string audio_channels{
        owned get {
			return gtk_combobox_get_value(cmb_channels,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmb_channels, 1, value);
		}
    }

    public string audio_sampling{
        owned get {
			return gtk_combobox_get_value(cmb_sampling,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmb_sampling, 1, value);
		}
    }

    public bool sox_enabled{
        get {
			return switch_sox.active;
		}
        set {
			switch_sox.set_active((bool)value);
		}
    }

    public string sox_bass{
        owned get {
			return scale_bass.get_value().to_string();
		}
        set {
			scale_bass.set_value(double.parse(value));
		}
    }

    public string sox_treble{
        owned get {
			return scale_treble.get_value().to_string();
		}
        set {
			scale_treble.set_value(double.parse(value));
		}
    }

    public string sox_pitch{
        owned get {
			return "%.1f".printf(scale_pitch.get_value()/100);
		}
        set {
			scale_pitch.set_value(double.parse(value) * 100);
		}
    }

    public string sox_tempo{
        owned get {
			return "%.1f".printf(scale_tempo.get_value()/100);
		}
        set {
			scale_tempo.set_value(double.parse(value) * 100);
		}
    }

    public string sox_fade_in{
        owned get {
			return spin_fade_in.get_value().to_string();
		}
        set {
			spin_fade_in.set_value(double.parse(value));
		}
    }

    public string sox_fade_out{
        owned get {
			return spin_fade_out.get_value().to_string();
		}
        set {
			spin_fade_out.set_value(double.parse(value));
		}
    }

    public string sox_fade_type{
        owned get {
			return gtk_combobox_get_value(cmb_fade_type,1,"l");
		}
        set {
			gtk_combobox_set_value(cmb_fade_type, 1, value);
		}
    }

    public bool sox_normalize{
        get {
			return chk_normalize.active;
		}
        set {
			chk_normalize.set_active((bool)value);
		}
    }

    public bool sox_earwax{
        get {
			return chk_earwax.active;
		}
        set {
			chk_earwax.set_active((bool)value);
		}
    }

    public string subtitle_mode{
        owned get {
			return gtk_combobox_get_value(cmb_sub_mode,1,"disable");
		}
        set {
			gtk_combobox_set_value(cmb_sub_mode, 1, value);
		}
    }

    public bool copy_tags{
		get {
			return chk_copy_tags.active;
		}
        set {
			chk_copy_tags.set_active((bool)value);
		}
    }
}
