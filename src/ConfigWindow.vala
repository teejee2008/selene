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

public class ConfigWindow : Dialog {

	private Notebook tabMain;
	private Box vboxMain;
	private Box vboxVideo;
	private Box hboxVPreset;

	private Label lblGeneral;
	private Grid gridGeneral;
	
	private Label lblVideo;
	private Grid gridVideo;
	private SpinButton spinCRF;
	
	private Scale scaleCRF;
	private Label lblCRF;
	
	private ComboBox cmbX264Preset;
	private Label lblX264Preset;
	private Scale scaleX264Preset;
	
	private ComboBox cmbX264Profile;
	private Label lblX264Profile;
	private Scale scaleX264Profile;
	
	string[] x264_presets = {"UltraFast","SuperFast","VeryFast","Faster","Fast","Medium","Slow","Slower","VerySlow"};
	string[] x264_profiles = {"Baseline","Main","High","High10","High422","High444"};
	
	private CheckButton chkOutput;
	private FileChooserButton fcbOutput;
	private CheckButton chkBackup;
	private Label lblBackup;
	private FileChooserButton fcbBackup;
	private Button btnSave;
	private Button btnCancel;
	
	public ConfigWindow () 
	{
		this.deletable = false; // remove window close button
		this.modal = true;
		set_default_size (500, 400);	

		// get content area
		vboxMain = get_content_area ();
		vboxMain.margin = 6;
		
		// tabMain
		tabMain = new Notebook ();
		vboxMain.pack_start (tabMain, true, true, 0);
		
		// lblGeneral
		lblGeneral = new Label ("General");

        //gridGeneral
        gridGeneral = new Grid ();
        gridGeneral.set_column_spacing (6);
        gridGeneral.set_row_spacing (6);
        gridGeneral.visible = false;
        tabMain.append_page (gridGeneral, lblGeneral);
/*        
        // lblVideo
        lblVideo = new Label ("Video");
        // vboxVideo
        vboxVideo = new Box (Orientation.VERTICAL, 6);
        tabMain.append_page (vboxVideo, lblVideo);
        
        */
        

		// lblVideo
		lblVideo = new Label ("Video");

        //gridVideo
        gridVideo = new Grid ();
        gridVideo.set_column_spacing (6);
        gridVideo.set_row_spacing (6);
        gridVideo.visible = false;
        gridVideo.margin = 12;
        //vboxVideo.add (gridVideo);
        tabMain.append_page (gridVideo, lblVideo);
        
        
        int gridrow = 0;
        ListStore model;
        CellRendererText textCell;
        
        // lblPreset
		lblX264Preset = new Gtk.Label("Preset");
		lblX264Preset.xalign = (float) 0.0;
		gridVideo.attach(lblX264Preset,0,gridrow,1,1);

		// cmbx264Preset
		model = new ListStore( 1, typeof( string ) );
		cmbX264Preset = new ComboBox.with_model(model);
		gridVideo.attach(cmbX264Preset,2,gridrow,1,1);
		
		textCell = new CellRendererText();
        cmbX264Preset.pack_start( textCell, false );
        cmbX264Preset.set_attributes( textCell, "text", 0 );
        foreach(string s in x264_presets){
        	TreeIter iter;
        	model.append( out iter );
        	model.set( iter, 0, s);
        }
        cmbX264Preset.set_active (0);
        
		// scalePreset
		Gtk.Adjustment adjPreset = new Gtk.Adjustment(5.0, 0.0, x264_presets.length - 1, 1.0, 1.0, 0.0);
		scaleX264Preset = new Gtk.Scale(Orientation.HORIZONTAL, adjPreset);
		scaleX264Preset.draw_value = false;
		scaleX264Preset.show_fill_level = true;
		scaleX264Preset.has_origin = true;
		scaleX264Preset.value_changed.connect (scalePreset_value_changed);
		scaleX264Preset.set_tooltip_text ("<< Faster Encoding | Smaller Files >>");
		gridVideo.attach(scaleX264Preset,1,gridrow,1,1);
		
		
		gridrow++;
		
		// lblProfile
	    
		lblX264Profile = new Gtk.Label("Profile");
		lblX264Profile.xalign = (float) 0.0;
		gridVideo.attach(lblX264Profile,0,gridrow,1,1);
	
		// cmbX264Profile
		model = new ListStore( 1, typeof( string ) );
		cmbX264Profile = new ComboBox.with_model(model);
		gridVideo.attach(cmbX264Profile,2,gridrow,1,1);
		
		textCell = new CellRendererText();
        cmbX264Profile.pack_start( textCell, false );
        cmbX264Profile.set_attributes( textCell, "text", 0 );
        foreach(string s in x264_profiles){
        	TreeIter iter;
        	model.append( out iter );
        	model.set( iter, 0, s);
        }
        cmbX264Profile.set_active (0);
        
		// scaleProfile
		
		Gtk.Adjustment adjProfile = new Gtk.Adjustment(2.0, 0.0, x264_profiles.length - 1, 1.0, 1.0, 0.0);
		scaleX264Profile = new Gtk.Scale(Orientation.HORIZONTAL, adjProfile);
		scaleX264Profile.draw_value = false;
		scaleX264Profile.show_fill_level = true;
		scaleX264Profile.has_origin = true;
		scaleX264Profile.value_changed.connect (scaleProfile_value_changed);
		gridVideo.attach(scaleX264Profile,1,gridrow,1,1);
		gridrow++;

        // lblCrf
		lblCRF = new Gtk.Label("CRF");
		//lblCRF.width_request = 100;
		lblCRF.xalign = (float) 0.0;
		gridVideo.attach(lblCRF,0,gridrow,1,1);

		// adjCRF
		Gtk.Adjustment adjCRF = new Gtk.Adjustment(22.0, 0.0, 51.0, 0.1, 1.0, 0.0);

		// spinCRF
		spinCRF = new Gtk.SpinButton (adjCRF, 0.1, 2);
		gridVideo.attach(spinCRF,2,gridrow,1,1);
		
		// scaleCRF
		scaleCRF = new Gtk.Scale(Orientation.HORIZONTAL, adjCRF);
		scaleCRF.draw_value = false;
		scaleCRF.width_request = 300;
		scaleCRF.show_fill_level = true;
		scaleCRF.inverted = false;
		scaleCRF.has_origin = true;
		scaleCRF.set_tooltip_text ("<< Better Quality | Smaller Files >>");
		gridVideo.attach(scaleCRF,1,gridrow,1,1);

		gridrow++;

		
        // btnSave
        btnSave = (Button) add_button (Stock.SAVE, Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (btnSave_clicked);
        
        // btnCancel
        btnCancel = (Button) add_button (Stock.CANCEL, Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (() => { this.destroy (); });
	}

	private void scalePreset_value_changed ()
    {
	    int index = (int) scaleX264Preset.adjustment.value;
	    cmbX264Preset.set_active (index);
	}
	
	private void scaleProfile_value_changed ()
    {
	    int index = (int) scaleX264Profile.adjustment.value;
	    cmbX264Profile.set_active (index);
	}

	private void btnSave_clicked ()
	{

		this.destroy ();
	}
}
