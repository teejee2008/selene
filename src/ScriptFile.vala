using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class ScriptFile : GLib.Object{
	public string Path;
	public string Name;
	public string Title;
	public string Extension;
	public string Folder;

	public ScriptFile(string filePath)
	{
		Path = filePath;
	    Name = GLib.Path.get_basename (filePath);
	    Folder = GLib.Path.get_dirname (filePath);

	    int index = Name.index_of(".");
	    if (index != -1){
			Title = Name[0:Name.last_index_of(".")];
			Extension = Name[Name.last_index_of("."):Name.length];
		}
		else{
			Title = Name;
			Extension = "";
		}
	}
}
