/*
 * CropVideoSingleWindow.vala
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
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class CropVideoSingleWindow : Gtk.Window {
	private Gtk.Box vboxMain;
	private Gtk.DrawingArea canvas;
	private Gtk.Scale scalePos;
	private Gtk.ComboBox cmbZoom;

	private Gtk.SpinButton spinCropL;
	private Gtk.SpinButton spinCropR;
	private Gtk.SpinButton spinCropT;
	private Gtk.SpinButton spinCropB;
	
	private Gtk.Label lblSourceSize;
	private Gtk.Label lblCroppedSize;

	private MediaPlayer player;
	private MediaFile mFile;

	private uint tmr_init = 0;

	public CropVideoSingleWindow(Gtk.Window parent, MediaFile _mFile) {
		set_transient_for(parent);
		set_destroy_with_parent(true);
        //set_skip_taskbar_hint(true);

		window_position = WindowPosition.CENTER_ALWAYS;
		icon = get_app_icon(16);
		
		modal = true;
		deletable = true;
		resizable = false;
		
		player = new MediaPlayer();
		player.mFile = _mFile;
		mFile = _mFile;
		
		title = "Crop Video";

		vboxMain = new Gtk.Box(Orientation.VERTICAL,6);
		//vboxMain = get_content_area () as Gtk.Box;
		add(vboxMain);

		init_ui_file_crop_options();

		init_ui_player();

		this.destroy.connect(()=>{ parent.show(); });
		
		show_all();
		
		tmr_init = Timeout.add(100, init_delayed);
	}
	
	private bool init_delayed() {
		/* any actions that need to run after window has been displayed */
		
		if (tmr_init > 0) {
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		load_file();

		return false;
	}
	
	private void init_ui_file_crop_options(){
		var grid = new Gtk.Grid();
		grid.margin = 6;
		grid.row_spacing = 3;
		grid.column_spacing = 3;
		vboxMain.add(grid);
		
		Gtk.Adjustment adj;
		Gtk.SpinButton spin;
		Gtk.Label label;

		string tt = _("Scroll mouse wheel to adjust");
		
		//left
		label = new Gtk.Label(_("Left:"));
		label.xalign = (float) 1.0;
		//label.margin_left = 18;
		grid.attach(label,0,0,1,1);
		
		//left
		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,1,0,1,1);
		
		spinCropL = spin;
	

		//right
		label = new Gtk.Label(_("Right:"));
		label.xalign = (float) 1.0;
		//label.margin_left = 18;
		grid.attach(label,0,1,1,1);
		
		//right
		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,1,1,1,1);

		spinCropR = spin;
		

		//top
		label = new Gtk.Label(_("Top:"));
		label.xalign = (float) 1.0;
		//label.margin_left = 18;
		grid.attach(label,2,0,1,1);
		
		//top
		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,3,0,1,1);

		spinCropT = spin;
		

		//bottom
		label = new Gtk.Label(_("Bottom:"));
		label.xalign = (float) 1.0;
		//label.margin_left = 18;
		grid.attach(label,2,1,1,1);
		
		//bottom
		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,3,1,1,1);
		
		spinCropB = spin;

		label = new Gtk.Label(_("Source:"));
		label.xalign = (float) 1.0;
		label.margin_left = 18;
		grid.attach(label,4,0,1,1);

		label = new Gtk.Label(_("Cropped:"));
		label.xalign = (float) 1.0;
		label.margin_left = 18;
		grid.attach(label,4,1,1,1);

		lblSourceSize = new Gtk.Label("0x0");
		lblSourceSize.xalign = (float) 1.0;
		grid.attach(lblSourceSize,5,0,1,1);

		lblCroppedSize = new Gtk.Label("0x0");
		lblCroppedSize.xalign = (float) 1.0;
		grid.attach(lblCroppedSize,5,1,1,1);

		var button = new Button.with_label(_("Detect Borders"));
		button.margin_left = 18;
		button.set_tooltip_text(_("Detect black borders in the video and set cropping parameters"));
        grid.attach(button,6,0,1,1);

		button.clicked.connect(btnDetect_clicked);

		button = new Button.with_label(_("OK"));
		button.margin_left = 18;
        grid.attach(button,6,1,1,1);

        button.clicked.connect(()=>{ this.destroy(); });
	}

	private void spin_value_changed_connect(){
		spinCropL.value_changed.connect(spinCropL_value_changed);
		spinCropR.value_changed.connect(spinCropR_value_changed);
		spinCropT.value_changed.connect(spinCropT_value_changed);
		spinCropB.value_changed.connect(spinCropB_value_changed);
	}
	
	private void spin_value_changed_disconnect(){
		spinCropL.value_changed.disconnect(spinCropL_value_changed);
		spinCropR.value_changed.disconnect(spinCropR_value_changed);
		spinCropT.value_changed.disconnect(spinCropT_value_changed);
		spinCropB.value_changed.disconnect(spinCropB_value_changed);
	}
	
	private void spinCropL_value_changed(){
		int original = mFile.CropL;
		int modified = (int) spinCropL.get_value();
		int change = modified - original;
		mFile.CropL = modified;
		
		player.ChangeRectangle(2, change);
		player.ChangeRectangle(0, -change);
		player.FrameStep();
		
		update_label_for_cropped_size();
	}

	private void spinCropR_value_changed(){
		int original = mFile.CropR;
		int modified = (int) spinCropR.get_value();
		int change = modified - original;
		mFile.CropR = modified;
		
		//player.ChangeRectangle(2, change);
		player.ChangeRectangle(0, -change);
		player.FrameStep();
		
		update_label_for_cropped_size();
	}

	private void spinCropT_value_changed(){
		int original = mFile.CropT;
		int modified = (int) spinCropT.get_value();
		int change = modified - original;
		mFile.CropT = modified;
		
		player.ChangeRectangle(3, change);
		player.ChangeRectangle(1, -change);
		player.FrameStep();
		
		update_label_for_cropped_size();
	}

	private void spinCropB_value_changed(){
		int original = mFile.CropB;
		int modified = (int) spinCropB.get_value();
		int change = modified - original;
		mFile.CropB = modified;
		
		//player.ChangeRectangle(3, change);
		player.ChangeRectangle(1, -change);
		player.FrameStep();
		
		update_label_for_cropped_size();
	}
	
	private void init_ui_player(){
		var hboxSlider = new Gtk.Box(Orientation.HORIZONTAL,6);
		hboxSlider.margin_left = 6;
		hboxSlider.margin_right = 6;
		//hboxSlider.set_size_request(600,600);
		vboxMain.add(hboxSlider);
		
		scalePos = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, (mFile.Duration/1000), 1);
		scalePos.adjustment.value = 0;
		scalePos.has_origin = false;
		scalePos.draw_value = false;
		scalePos.expand = true;
		//scalePos.value_pos = PositionType.RIGHT;
		hboxSlider.add(scalePos);

		scalePos.value_changed.connect (() => {
			player.Seek(scalePos.get_value());
		});

		//cmbZoom
		cmbZoom = new ComboBox();
		var textCell = new CellRendererText();
        cmbZoom.pack_start(textCell, false);
        cmbZoom.set_attributes(textCell, "text", 0);
        hboxSlider.add(cmbZoom);

        //populate
        TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("25%"),1,"0.25");
		model.append (out iter);
		model.set (iter,0,_("50%"),1,"0.50");
		model.append (out iter);
		model.set (iter,0,_("75%"),1,"0.75");
		model.append (out iter);
		model.set (iter,0,_("100%"),1,"1.0");
		model.append (out iter);
		model.set (iter,0,_("200%"),1,"2.0");
		cmbZoom.set_model(model);

		if (mFile.SourceWidth > (Gdk.Screen.get_default().get_width() / 2)){
			cmbZoom.active = 2;
		}
		else{
			cmbZoom.active = 3;
		}
		
		cmbZoom.changed.connect(cmbZoom_changed);
		
		canvas = new Gtk.DrawingArea();
		canvas.set_size_request(400,300);
		canvas.expand = true;
		canvas.halign = Align.START;
		vboxMain.pack_start (canvas, false, false, 0);

        this.canvas.realize.connect(() => {
			player.WindowID = get_widget_xid(canvas);
			player.StartPlayerWithRectangle();
		});

		this.delete_event.connect(()=>{
			player.Exit();
			return false;
		});
	}


	private void load_file(){
		cmbZoom_changed();
		player.Open(mFile, true, true, true);

        spin_value_changed_disconnect();
        
		spinCropL.adjustment.value = mFile.CropL;
		spinCropR.adjustment.value = mFile.CropR;
		spinCropT.adjustment.value = mFile.CropT;
		spinCropB.adjustment.value = mFile.CropB;
		
		lblSourceSize.label = "%dx%d".printf(mFile.SourceWidth,mFile.SourceHeight);
		update_label_for_cropped_size();
		
		spin_value_changed_connect();

		//player.SetRectangle();
		//player.FrameStep();
	}
	
	private void btnDetect_clicked(){
		player.Exit();
		//sleep(2000);
		player.StartPlayerWithCropDetect();
		player.Open(mFile, false, true, true);

		
		var status_msg = _("Detecting borders...");
		var dlg = new SimpleProgressWindow.with_parent(this, status_msg);
		dlg.set_title(_("Please Wait..."));
		dlg.show_all();
		gtk_do_events();

		//get total count
		App.progress_total = 10;
		App.progress_count = 0;

		mFile.CropL = 9999;
		mFile.CropR = 9999;
		mFile.CropT = 9999;
		mFile.CropB = 9999;
		
		double duration = (mFile.Duration / 1000.0);
		double step = duration / 10.0;
		for(int i = 0; i < 10; i++){
			player.Seek(step * i);
			sleep(100);
			App.progress_count++;
			dlg.update_progressbar();
		}

		dlg.finish(_("Detected Parameters: %d, %d, %d, %d").printf(mFile.CropL,mFile.CropR,mFile.CropT,mFile.CropB));
		
		//dlg.close();
		//gtk_do_events();

		player.Exit();
		player.StartPlayerWithRectangle();

		load_file();
	}
	
	private void update_label_for_cropped_size(){
		lblCroppedSize.label = "%dx%d".printf((mFile.SourceWidth - mFile.CropL - mFile.CropR),(mFile.SourceHeight - mFile.CropT - mFile.CropB));
	}

	private void cmbZoom_changed(){
		double zoom = double.parse(gtk_combobox_get_value(cmbZoom,1,"1.0"));
		int zoomWidth = (int) (mFile.SourceWidth * zoom * 1.0);
		int zoomHeight = (int) (mFile.SourceHeight * zoom * 1.0);
		canvas.set_size_request(zoomWidth, zoomHeight);
		this.resize(1,1);
		gtk_do_events();
	}
}

