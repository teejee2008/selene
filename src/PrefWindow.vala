/*
 * PrefWindow.vala
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

public class PrefWindow : Dialog {

	private Box vboxMain;
	private Label lblOutput;
	private CheckButton chkOutput;
	private FileChooserButton fcbOutput;
	private CheckButton chkBackup;
	private Label lblBackup;
	private FileChooserButton fcbBackup;
	private Button btnSave;
	private Button btnCancel;
	
	public PrefWindow() {
		this.deletable = false; // remove window close button
		this.modal = true;
		this.title = "Application Settings";
		set_default_size (500, 400);	
		
		//set app icon
		try{
			this.icon = new Gdk.Pixbuf.from_file ("""/usr/share/pixmaps/selene.png""");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
		// get content area
		vboxMain = get_content_area();
		vboxMain.margin = 6;
		
		// lblOutput
		lblOutput = new Label (_("<b>Output Folder</b>"));
		lblOutput.set_use_markup(true);
		lblOutput.halign = Align.START;
		lblOutput.margin_bottom = 6;
		lblOutput.margin_top = 6;
		vboxMain.pack_start (lblOutput, false, true, 0);
		
		// fcbOutput
		fcbOutput = new FileChooserButton (_("Output Location"), FileChooserAction.SELECT_FOLDER);
		fcbOutput.set_sensitive(App.OutputDirectory.length > 0);
		fcbOutput.margin_bottom = 6;
		if ((App.OutputDirectory != null) && Utility.dir_exists (App.OutputDirectory)){
			fcbOutput.set_filename (App.OutputDirectory);
		}
		vboxMain.add (fcbOutput);

		// chkOutput
		chkOutput = new CheckButton.with_label (_("Save in input file location"));
		chkOutput.active = (App.OutputDirectory.length == 0);
		chkOutput.clicked.connect (chkOutput_clicked);
		vboxMain.pack_start (chkOutput, false, true, 0);
				
		// lblBackup
		lblBackup = new Label (_("<b>Backup Folder</b>"));
		lblBackup.set_use_markup(true);
		lblBackup.halign = Align.START;
		lblBackup.margin_bottom = 6;
		lblBackup.margin_top = 6;
		vboxMain.pack_start (lblBackup, false, true, 0);
	
		// fcbBackup
		fcbBackup = new FileChooserButton (_("Backup Location"), FileChooserAction.SELECT_FOLDER);
		fcbBackup.set_sensitive(App.BackupDirectory.length > 0);
		fcbBackup.margin_bottom = 6;
		if ((App.BackupDirectory.length > 0) && Utility.dir_exists (App.BackupDirectory)){
			fcbBackup.set_filename (App.BackupDirectory);
		}
		vboxMain.add (fcbBackup);
		
		// chkBackup
		chkBackup = new CheckButton.with_label (_("Do not move input files"));
		chkBackup.active = (App.BackupDirectory.length == 0);
		chkBackup.clicked.connect (chkBackup_clicked);
		vboxMain.pack_start (chkBackup, false, true, 0);
		
        // btnSave
        btnSave = (Button) add_button (Stock.SAVE, Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (btnSave_clicked);
        
        // btnCancel
        btnCancel = (Button) add_button (Stock.CANCEL, Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (btnCancel_clicked);
	}
	
	private void chkOutput_clicked(){
		fcbOutput.set_sensitive(!chkOutput.active);
	}
	
	private void chkBackup_clicked(){
		fcbBackup.set_sensitive(!chkBackup.active);
	}
	
	private void btnSave_clicked(){
		if (chkOutput.active){
			App.OutputDirectory = "";
		}
		else {
			if (Utility.dir_exists (fcbOutput.get_filename())){
				App.OutputDirectory = fcbOutput.get_filename();
			}
		}
		
		if (chkBackup.active){
			App.BackupDirectory = "";
		}
		else {
			if (Utility.dir_exists (fcbBackup.get_filename())){
				App.BackupDirectory = fcbBackup.get_filename();
			}
		}
		
		// Save settings
		var settings = new GLib.Settings ("apps.selene");
		settings.set_string ("backup-dir", App.BackupDirectory);
		settings.set_string ("output-dir", App.OutputDirectory);
		
		this.destroy();
	}
	
	private void btnCancel_clicked(){
		this.destroy();
	}
}
