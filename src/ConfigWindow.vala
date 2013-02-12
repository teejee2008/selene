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
	
	public string SelectedScriptPath;
	
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
	
	private CheckButton chkOutput;
	private FileChooserButton fcbOutput;
	private CheckButton chkBackup;
	private Label lblBackup;
	private FileChooserButton fcbBackup;
	private Button btnSave;
	private Button btnCancel;
	
	private string _preset;
	private string _profile;
	private double _crf;
	
	public ConfigWindow () 
	{
		this.deletable = false; // remove window close button
		this.modal = true;
		set_default_size (500, 400);	
		
		int gridrow = 0;
        Gtk.ListStore model;
        Gtk.CellRendererText textCell;
        Gtk.TreeIter iter;
        
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

		// lblVideo
		lblVideo = new Label ("Video (x264)");

        //gridVideo
        gridVideo = new Grid ();
        gridVideo.set_column_spacing (6);
        gridVideo.set_row_spacing (6);
        gridVideo.visible = false;
        gridVideo.margin = 12;
        //vboxVideo.add (gridVideo);
        tabMain.append_page (gridVideo, lblVideo);
        
        
        
        // lblPreset
		lblX264Preset = new Gtk.Label("Preset");
		lblX264Preset.xalign = (float) 0.0;
		gridVideo.attach(lblX264Preset,0,0,1,1);
		
		// cmbx264Preset
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
        cmbX264Preset.set_active (3);
        gridVideo.attach(cmbX264Preset,1,0,1,1);
        
		// scalePreset
		/*Gtk.Adjustment adjPreset = new Gtk.Adjustment(5.0, 0.0, x264_presets.length - 1, 1.0, 1.0, 0.0);
		scaleX264Preset = new Gtk.Scale(Orientation.HORIZONTAL, adjPreset);
		scaleX264Preset.draw_value = false;
		scaleX264Preset.show_fill_level = true;
		scaleX264Preset.has_origin = true;
		scaleX264Preset.value_changed.connect (scalePreset_value_changed);
		scaleX264Preset.set_tooltip_text ("<< Faster Encoding | Smaller Files >>");
		//gridVideo.attach(scaleX264Preset,2,gridrow,1,1);*/


		// lblProfile
		lblX264Profile = new Gtk.Label("Profile");
		lblX264Profile.xalign = (float) 0.0;
		gridVideo.attach(lblX264Profile,0,1,1,1);
	
		// cmbX264Profile
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
        cmbX264Profile.set_active (2);
        gridVideo.attach(cmbX264Profile,1,1,1,1);
        
		// scaleProfile
		/*Gtk.Adjustment adjProfile = new Gtk.Adjustment(2.0, 0.0, x264_profiles.length - 1, 1.0, 1.0, 0.0);
		scaleX264Profile = new Gtk.Scale(Orientation.HORIZONTAL, adjProfile);
		scaleX264Profile.draw_value = false;
		scaleX264Profile.show_fill_level = true;
		scaleX264Profile.has_origin = true;
		scaleX264Profile.value_changed.connect (scaleProfile_value_changed);
		//gridVideo.attach(scaleX264Profile,2,gridrow,1,1);
		gridrow++;*/

        // lblCrf
		lblCRF = new Gtk.Label("CRF");
		//lblCRF.width_request = 100;
		lblCRF.xalign = (float) 0.0;
		gridVideo.attach(lblCRF,0,2,1,1);

		// adjCRF
		Gtk.Adjustment adjCRF = new Gtk.Adjustment(22.0, 0.0, 51.0, 0.1, 1.0, 0.0);

		// spinCRF
		spinCRF = new Gtk.SpinButton (adjCRF, 0.1, 2);
		gridVideo.attach(spinCRF,1,2,1,1);
		
		// scaleCRF
		scaleCRF = new Gtk.Scale(Orientation.HORIZONTAL, adjCRF);
		scaleCRF.draw_value = false;
		scaleCRF.width_request = 300;
		scaleCRF.show_fill_level = true;
		scaleCRF.inverted = false;
		scaleCRF.has_origin = true;
		scaleCRF.set_tooltip_text ("<< Better Quality | Smaller Files >>");
		//gridVideo.attach(scaleCRF,2,gridrow,1,1);

		gridrow++;

		
        // btnSave
        btnSave = (Button) add_button (Stock.SAVE, Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (btnSave_clicked);
        
        // btnCancel
        btnCancel = (Button) add_button (Stock.CANCEL, Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (() => { this.destroy (); });
        
	}

	private void btnSave_clicked ()
	{
		save_script();
		this.destroy ();
	}
	
	public void load_script()
	{
		try {
		    var file = File.parse_name (SelectedScriptPath);
	        var dis = new DataInputStream (file.read ());

	        MatchInfo match;
	        Regex rxPreset = new Regex ("""x264.*--preset ([a-z]+) """);
	        Regex rxProfile = new Regex ("""x264.*--profile ([a-z0-9]+) """);
	        Regex rxCRF = new Regex ("""x264.*--crf ([0-9]+[.]?[0-9]*) """);

	        string line = dis.read_line (null);
	        while (line != null) {
				//preset
				if (rxPreset.match (line, 0, out match)){
					preset = match.fetch(1);
				}
				//profile
				if (rxProfile.match (line, 0, out match)){
					profile = match.fetch(1);
				}
				//crf
				if (rxCRF.match (line, 0, out match)){
					crf = match.fetch(1);
				}
				
				line = dis.read_line (null);
	        }
	    } catch (Error e) {
	        log_error (e.message);
	    }
	}
	
	private void save_script()
	{
		var script = new StringBuilder ();
		
		try {
		    var file = File.parse_name (SelectedScriptPath);
	        var dis = new DataInputStream (file.read ());

	        MatchInfo match;
	        Regex rxPreset = new Regex ("""x264.*-preset ([a-z]+) """);

	        string line = dis.read_line (null);
	        while (line != null) {
				//preset
				if (rxPreset.match (line, 0, out match)){
					line = line.replace (match.fetch(1), preset);
				}
				//profile
				if (rxProfile.match (line, 0, out match)){
					line = line.replace (match.fetch(1), profile);
				}
				//crf
				if (rxCRF.match (line, 0, out match)){
					line = line.replace (match.fetch(1), CRF);
				}
		        script.append (line + "\n");
		        line = dis.read_line (null);
	        }
	        
	        dis.close();
	        dis = null;
	        
	        FileUtils.set_contents (SelectedScriptPath, script.str); 
	    } catch (Error e) {
	        log_error (e.message);
	    }
		
	}
	
	public string preset 
	{
        get { 
			TreeIter iter;
			cmbX264Preset.get_active_iter (out iter);
			ListStore model = (ListStore) cmbX264Preset.model;
			model.get(iter, 1, out _preset);
			return _preset; 
		}
        set { 
			TreeIter iter;
			string val;
			ListStore model = (ListStore) cmbX264Preset.model;
			
			bool iterExists = model.get_iter_first (out iter);
			while (iterExists){
				model.get(iter, 1, out val);
				if (val == value){
					cmbX264Preset.set_active_iter(iter);
					_preset = value;
					break;
				}
				iterExists = model.iter_next (ref iter);
			} 
		}
    }
    
    public string profile
	{
        get { 
			TreeIter iter;
			cmbX264Preset.get_active_iter (out iter);
			ListStore model = (ListStore) cmbX264Preset.model;
			model.get(iter, 1, out _preset);
			return _preset; 
		}
        set { 
			TreeIter iter;
			string val;
			ListStore model = (ListStore) cmbX264Preset.model;
			
			bool iterExists = model.get_iter_first (out iter);
			while (iterExists){
				model.get(iter, 1, out val);
				if (val == value){
					cmbX264Preset.set_active_iter(iter);
					_preset = value;
					break;
				}
				iterExists = model.iter_next (ref iter);
			} 
		}
    }
    
    public string crf 
	{
        get { 
			TreeIter iter;
			cmbX264Preset.get_active_iter (out iter);
			ListStore model = (ListStore) cmbX264Preset.model;
			model.get(iter, 1, out _preset);
			return _preset; 
		}
        set { 
			TreeIter iter;
			string val;
			ListStore model = (ListStore) cmbX264Preset.model;
			
			bool iterExists = model.get_iter_first (out iter);
			while (iterExists){
				model.get(iter, 1, out val);
				if (val == value){
					cmbX264Preset.set_active_iter(iter);
					_preset = value;
					break;
				}
				iterExists = model.iter_next (ref iter);
			} 
		}
    }
}
