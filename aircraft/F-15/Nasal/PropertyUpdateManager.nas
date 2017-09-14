 #---------------------------------------------------------------------------
 # Property / object update manager
 #
 # - Manage updates when a value has changed more than a predetermined amount.
 #   This class is designed to make updating displays (e.g. canvas), or
 #   performing actions based on a property (or value in a hash) changing
 #   by more than the preset amount.
 #   This can make a significant improvement to performance compared to simply
 #   redrawing a canvas in an update loop.
 # - Author       : Richard Harrison (rjh@zaretto.com)
 #---------------------------------------------------------------------------*/

#example usage:
# this is using the hashlist (which works well with an Emesary notification)
# basically when the method is called it will call each section (in the lambda)
# when the value changes by more than the amount specified as the second parameter.
# It is possible to reference multiple elements from the hashlist in each newFromHashList; if either
# one changes then it will result in the lambda being called.
#
#        obj.update_items = [
#            UpdateManager.newFromHashList(["VV_x","VV_y"], 0.01, func(val)
#                                      {
#                                        obj.VV.setTranslation (val.VV_x, val.VV_y + pitch_offset);
#                                      }),
#            UpdateManager.newFromHashList(["pitch","roll"], 0.025, func(hdp)
#                                      {
#                                          obj.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
#                                          obj.ladder.setCenter (118,830 - hdp.pitch * pitch_factor-pitch_offset);
#                                          obj.ladder.setRotation (-hdp.roll_rad);
#                                          obj.roll_pointer.setRotation (hdp.roll_rad);
#                                      }),
#            props.UpdateManager.FromProperty("velocities/airspeed-kt", 0.01, func(val)
#                                      {
#                                          obj.ias_range.setTranslation(0, val * ias_range_factor);
#                                      }),
#                            props.UpdateManager.FromPropertyHashList(["orientation/alpha-indicated-deg", "orientation/side-slip-deg"], 0.1, func(val)
#                                                                     {
#                                                                         obj.VV_x = val.property["orientation/side-slip-deg"].getValue()*10; # adjust for view
#                                                                         obj.VV_y = val.property["orientation/alpha-indicated-deg"].getValue()*10; # adjust for view
#                                                                         obj.VV.setTranslation (obj.VV_x, obj.VV_y);
#                                                                     }),
#           ]
#
#==== the update loop then becomes ======
# 
#        foreach(var update_item; me.update_items)
#        {
#            # hdp is a data provider that can be used as the hashlist for the property
#            # update from hash methods.
#            update_item.update(hdp);
#        }
#
var UpdateManager =
{
 _updateProperty : func(_property)
 {
 },
    FromProperty : func(_propname, _delta, _changed_method)
    {
        var obj = {parents : [UpdateManager] };
        obj.propname = _propname;
        obj.property = props.globals.getNode(_propname);
        obj.delta = _delta;
        obj.curval = obj.property.getValue();
        obj.lastval = obj.curval;
        obj.changed = _changed_method;
        obj.update = func(obj)
        {
            me.curval = me.property.getValue();
            if (me.curval != nil)
            {
                me.localType = me.property.getType();
                if (me.localType == "INT" or me.localType == "LONG" or me.localType == "FLOAT" or me.localType == "DOUBLE")
                  {
                      if(me.lastval == nil or math.abs(me.lastval - me.curval) >= me.delta)
                        {
                            me.lastval = me.curval;
                            me.changed(me.curval);
                        }
                  }
                else if(me.lastval == nil or me.lastval != me.curval)
                  {
                      me.lastval = me.curval;
                      me.changed(me.curval);
                  }
            }
        };
        obj.update(obj);
        return obj;
    },

    IsNumeric : func(hashkey)
    {
        me.localType = me.property[hashkey].getType();
        if (me.localType == "UNSPECIFIED") {
            print("UpdateManager: warning ",hashkey," is ",ty, " excluding from update");
            me.property[hashkey] = nil;
        }
        if (me.localType == "INT" or me.localType == "LONG" or me.localType == "FLOAT" or me.localType == "DOUBLE")
          return 1;
        else
          return 0;
    },

    FromPropertyHashList : func(_keylist, _delta, _changed_method)
    {
        var obj = {parents : [UpdateManager] };
        obj.hashkeylist = _keylist;
        obj.delta = _delta;
        obj.lastval = {};
        obj.hashkey = nil;
        obj.changed = _changed_method;
        obj.needs_update = 0;
        obj.property = {};
        obj.is_numeric = {};
        foreach (hashkey; obj.hashkeylist) {
            obj.property[hashkey] = props.globals.getNode(hashkey);
            obj.lastval[hashkey] = nil;
#            var ty = obj.property[hashkey].getType();
#            if (ty == "INT" or ty == "LONG" or ty == "FLOAT" or ty == "DOUBLE") {
#                obj.is_numeric[hashkey] = 1;
#            } else
#              obj.is_numeric[hashkey] = 0;
#print("create: ", hashkey," ", ty, " isnum=",obj.is_numeric[hashkey]);
#            if (ty == "UNSPECIFIED")
#              print("UpdateManager: warning ",hashkey," is ",ty);
        }
        obj.update = func(obj)
          {
              if (me.lastval == nil)
                  me.needs_update = 1;
              else {
                  me.needs_update = 0;

                  foreach (hashkey; me.hashkeylist) {
                      if (me.property[hashkey] != nil) {
                          me.valIsNumeric = me.IsNumeric(hashkey);

                          if (me.lastval[hashkey] == nil
                              or (me.valIsNumeric and (math.abs(me.lastval[hashkey] - me.property[hashkey].getValue()) >= me.delta))
                              or (!me.valIsNumeric and (me.lastval[hashkey] != me.property[hashkey].getValue()))) {
                              me.needs_update = 1;
                              break;
                          }
                      }
                  }
              }
              if (me.needs_update) {
                  me.changed(me);
                  foreach (hashkey; me.hashkeylist) {
                      me.lastval[hashkey] = me.property[hashkey].getValue();
                  }
              }
          }
        ;
        return obj;
    },
    FromHashValue : func(_key, _delta, _changed_method)
    {
        var obj = {parents : [UpdateManager] };
        obj.hashkey = _key;
        obj.delta = _delta;
        obj.isnum = _delta != nil;
        obj.curval = nil;
        obj.lastval = nil;
        obj.changed = _changed_method;
        obj.update = func(obj)
          {
              me.curval = obj[me.hashkey];
              if (me.curval != nil) {
                  if (me.isnum) {
                      me.curval = num(me.curval);
                      if (me.lastval == nil or math.abs(me.lastval - me.curval) >= me.delta) {
                          me.lastval = me.curval;
                          me.changed(me.curval);
                      }
                  } else {
                      if (me.lastval == nil or me.lastval != me.curval) {
                          me.lastval = me.curval;
                          me.changed(me.curval);
                      }
                  }
              }
          }
        ;
        return obj;
    },
    FromHashList : func(_keylist, _delta, _changed_method)
    {
        var obj = {parents : [UpdateManager] };
        obj.hashkeylist = _keylist;
        obj.delta = _delta;
        obj.lastval = {};
        obj.hashkey = nil;
        obj.changed = _changed_method;
        obj.needs_update = 0;
        obj.update = func(obj)
          {
              if (me.lastval == nil)
                me.needs_update = 1;
              else
                me.needs_update = 0;

              if (obj != nil or me.lastval == nil) {
                  foreach (hashkey; me.hashkeylist) {
                      if (me.lastval[hashkey] == nil or math.abs(me.lastval[hashkey] - obj[hashkey]) >= me.delta) {
                          me.needs_update = 1;
                          break;
                      }
                  }
              }
              if (me.needs_update) {
                  me.changed(obj);
                  foreach (hashkey; me.hashkeylist) {
                      me.lastval[hashkey] = obj[hashkey];
                  }
              }
          };
        return obj;
    },
};
