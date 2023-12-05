#---------------------------------------------------------------------------
 #
 #	Title                : Fallback nasal module loader
 #
 #	File Type            : Implementation File
 #
 #	Description          : permits the definition of fallback files for modules that have been 
 #                       : added to fgdata in a version after the minimum supported.
 #                       : 
 #                       : This allows an aircraft to use the fgdata if present (and benefit from
 #                       : bug fixes etc) whilst still working on an earlier version.
 #                       : The version from FGData will always be used when present.
 #
 #                       : define in /fallback/nasal
 #                       : in this case emexec will only be loaded (from file) if emexec.nas is
 #                       : not present in fgdata
 #                       : e.g.
 #                       :    <fallback>
 #                       :        <nasal>
 #                       :            <emexec>
 #                       :                <file>Aircraft/F-15/Nasal/fallback/emexec.nas</file>
 #                       :            </emexec>
 #                       :        </nasal>
 #                       :    </fallback>
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 14 July 2022
 #
 #  Copyright (C) 2022 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

var fallbackRoot = props.globals.getNode("fallback/nasal");
if (fallbackRoot != nil)
{
    foreach(var item ;  fallbackRoot.getChildren()){
        #debug.dump(item);
        var module=item.getName();
        var file =item.getNode("file").getValue();
        if (!contains(globals, module)) {
            var filename = resolvepath(file);
            logprint(3, sprintf("Loading fallback Nasal module for %s, file %s, path %s",module,file,filename));
           if (filename  != nil) {
                io.load_nasal(filename, module);
            }
        }
    }
}
