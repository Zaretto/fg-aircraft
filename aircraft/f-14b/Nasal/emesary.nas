#---------------------------------------------------------------------------
 #
 #	Title                : EMESARY inter-object communication
 #
 #	File Type            : Implementation File
 #
 #	Description          : Provides generic inter-object communication. For an object to receive a message it
 #	                     : must first register with an instance of a Transmitter, and provide a Receive method
 #
 #	                     : To send a message use a Transmitter with an object. That's all there is to it.
 #  
 #  References           : http://chateau-logic.com/content/emesary-nasal-implementation-flightgear
 #                       : http://www.chateau-logic.com/content/class-based-inter-object-communication
 #                       : http://chateau-logic.com/content/emesary-efficient-inter-object-communication-using-interfaces-and-inheritance
 #                       : http://chateau-logic.com/content/c-wpf-application-plumbing-using-emesary
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 29 January 2016
 #
 #	Version              : 4.8
 #
 #  Copyright © 2016 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

var __emesaryUniqueId = 14; # 0-15 are reserved, this way the global transmitter will be 15.

# Transmitters send notifications to all recipients that are registered.
var Transmitter =
{
    ReceiptStatus_OK : 0,          # Processing completed successfully
    ReceiptStatus_Fail : 1,        # Processing resulted in at least one failure
    ReceiptStatus_Abort : 2,       # Fatal error, stop processing any further recipieints of this message. Implicitly failed.
    ReceiptStatus_Finished : 3,    # Definitive completion - do not send message to any further recipieints
    ReceiptStatus_NotProcessed : 4,# Return value when method doesn't process a message.
    ReceiptStatus_Pending : 5,     # Message sent with indeterminate return status as processing underway
    ReceiptStatus_PendingFinished : 6,# Message definitively handled, status indeterminate. The message will not be sent any further

    # create a new transmitter. shouldn't need many of these
    new: func(_ident)
    {
        var new_class = { parents: [Transmitter]};
        new_class.Recipients = [];
        new_class.Ident = _ident;
        new_class.Timestamp = nil;
        new_class.MaxMilliseconds = 1;
        __emesaryUniqueId += 1;
        new_class.UniqueId = __emesaryUniqueId;
        return new_class;
    },
    OverrunDetection: func(max_ms=0){
          if (max_ms){
              if (me.Timestamp == nil)
                me.Timestamp = maketimestamp();
              me.MaxMilliseconds = max_ms;
#print("Set overrun detection ",me.Ident, " to ", me.MaxMilliseconds);
          } else {
              #              me.Timestamp = nil;
              me.MaxMilliseconds = 0;
#print("Disable  overrun detection ",me.Ident);
          }
      }
 ,

    # Add a recipient to receive notifications from this transmitter
    Register: func (recipient)
    {
        append(me.Recipients, recipient);
    },
    DeleteAllRecipients: func
    {
        me.Recipients = [];
    },
    # Stops a recipient from receiving notifications from this transmitter.
    DeRegister: func(todelete_recipient)
    {
        var out_idx = 0;
        var element_deleted = 0;

        for (var idx = 0; idx < size(me.Recipients); idx += 1)
        {
            if (me.Recipients[idx] != todelete_recipient)
            {
                me.Recipients[out_idx] = me.Recipients[idx];
                out_idx = out_idx + 1;
            }
            else
                element_deleted = 1;
        }

        if (element_deleted)
            pop(me.Recipients);
    },

    RecipientCount: func
    {
        return size(me.Recipients);
    },

    PrintRecipients: func
    {
        print("Emesary: Recipient list for ",me.Ident,"(",me.UniqueId,")");
        for (var idx = 0; idx < size(me.Recipients); idx += 1)
            print("Emesary: Recipient[",idx,"] ",me.Recipients[idx].Ident," (",me.Recipients[idx].UniqueId,")");
    },

    # Notify all registered recipients. Stop when receipt status of abort or finished are received.
    # The receipt status from this method will be 
    #  - OK > message handled
    #  - Fail > message not handled. A status of Abort from a recipient will result in our status
    #           being fail as Abort means that the message was not and cannot be handled, and
    #           allows for usages such as access controls.
    NotifyAll: func(message)
    {
        if (message == nil){
            print("Emesary: bad notification nil");
            return Transmitter.ReceiptStatus_NotProcessed;
        }
        me._return_status = Transmitter.ReceiptStatus_NotProcessed;
        me.TimeTaken = 0;
        foreach (var recipient; me.Recipients)
        {
            if (recipient.RecipientActive)
            {
                me._rstat = nil;
                if (me.MaxMilliseconds > 0 and me.Timestamp != nil)
                  me.Timestamp.stamp();

                message.Timestamp = me.Timestamp;
                call(func {me._rstat = recipient.Receive(message);},nil,nil,nil,var err = []);
                
                if (size(err)){
                    foreach(var line; err) {
                        print(line);
                    }
                    print("Recipient ",recipient.Ident, " has been removed from transmitter (", me.Ident, ") because of the above error");
                    me.DeRegister(recipient);
                    return Transmitter.ReceiptStatus_Abort;#need to break the foreach due to having modified what its iterating over.
                }
                if (me.Timestamp != nil) {
                    recipient.TimeTaken = me.Timestamp.elapsedUSec()/1000.0;
                    me.TimeTaken += recipient.TimeTaken;
                }

                if(me._rstat == Transmitter.ReceiptStatus_Fail)
                {
                    me._return_status = Transmitter.ReceiptStatus_Fail;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_Pending)
                {
                    me._return_status = Transmitter.ReceiptStatus_Pending;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_PendingFinished)
                {
                    return me._rstat;
                }
#               elsif(rstat == Transmitter.ReceiptStatus_NotProcessed)
#               {
#                   ;
#               }
                elsif(me._rstat == Transmitter.ReceiptStatus_OK)
                {
                    if (me._return_status == Transmitter.ReceiptStatus_NotProcessed)
                        me._return_status = me._rstat;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_Abort)
                {
                    return Transmitter.ReceiptStatus_Abort;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_Finished)
                {
                    return Transmitter.ReceiptStatus_OK;
                }
            }
        }
        if (me.MaxMilliseconds and me.TimeTaken > me.MaxMilliseconds ){
            printf("Overrun: %s ['%s'] %1.2fms max (%d)",me.Ident,message.NotificationType, me.TimeTaken,me.MaxMilliseconds);
#            print("Overrun: ",me.Ident, "['",message.NotificationType,"']", " ", me.TimeTaken,"ms  (max ",me.MaxMilliseconds," ms)");
            foreach (var recipient; me.Recipients) {
                if (recipient.TimeTaken)
                  printf(" -- Recipient %25s %7.2f ms",recipient.Ident, recipient.TimeTaken);
            }
        }
        return me._return_status;
    },

    # Returns true if a return value from NotifyAll is to be considered a failure.
    IsFailed: func(receiptStatus)
    {
        # Failed is either Fail or Abort.
        # NotProcessed isn't a failure because it hasn't been processed.
        if (receiptStatus == Transmitter.ReceiptStatus_Fail or receiptStatus == Transmitter.ReceiptStatus_Abort)
            return 1;
        return 0;
    }
};

#
#
# Base class for Notifications. By convention a Notification has a type and a value.
#   SubClasses can add extra properties or methods.
# Properties:
# Ident : Generic message identity. Can be an ident, or for simple messages a value that needs transmitting.
# NotificationType  : Notification Type
# IsDistinct : non zero if this message supercedes previous messages of this type.
#              Distinct messages are usually sent often and self contained
#              (i.e. no relative state changes such as toggle value)
#              Messages that indicate an event (such as after a pilot action)
#              will usually be non-distinct. So an example would be gear/up down
#              or ATC acknowledgements that all need to be transmitted
# The IsDistinct is important for any messages that are bridged over MP as
# only the most recently sent distinct message will be transmitted over MP
var NotificationAutoTypeId = 1;
var Notification =
{
    new: func(_type, _ident, _typeid=0)
    {
        var new_class = { parents: [Notification]};
        new_class.Ident = _ident;
        new_class.NotificationType = _type;
        new_class.IsDistinct = 1;
        new_class.FromIncomingBridge = 0;
        new_class.Callsign = nil;

        new_class.GetBridgeMessageNotificationTypeKey = func {
            return me.NotificationType~"."~me.Ident;
        };
        if (_typeid == 0)
        {
            _typeid = NotificationAutoTypeId;
            NotificationAutoTypeId = NotificationAutoTypeId + 1;
        }
        new_class.TypeId = _typeid;
        return new_class;
    },
};

# Inherit or implement class with the same signatures to receive messages.
var Recipient =
{
    new: func(_ident)
    {
        var new_class = { parents: [Recipient]};
        if (_ident == nil or _ident == "")
        {
            _ident = id(new_class);
            print("Emesary Error: Ident required when creating a recipient, defaulting to ",_ident);
        }
        Recipient.construct(_ident, new_class);
    },
    construct: func(_ident, new_class)
    {
        new_class.Ident = _ident;
        new_class.RecipientActive = 1;
        __emesaryUniqueId += 1;
        new_class.UniqueId = __emesaryUniqueId;
        new_class.Receive = func(notification)
        {
            # warning if required function not 
            print("Emesary Error: Receive function not implemented in recipient ",me.Ident);
            return Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};

#
# Instantiate a Global Transmitter, this is a convenience and a known starting point. Generally most classes will
# use this transmitters, however other transmitters can be created and merely use the global transmitter to discover each other
var GlobalTransmitter =  Transmitter.new("GlobalTransmitter");

#
#
# This is basically a base64 like encode except we just use alphanumerics which gives us a base62 encode.
var BinaryAsciiTransfer = 
{
# alphabet : "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    alphabet : chr(1)~chr(2)~chr(3)~chr(4)~chr(5)~chr(6)~chr(7)~chr(8)~chr(9)~chr(10)~chr(11)~chr(12)~chr(13)
               ~chr(14)~chr(15)~chr(16)~chr(17)~chr(18)~chr(19)~chr(20)~chr(21)~chr(22)~chr(23)~chr(24)~chr(25)
               ~chr(26)~chr(27)~chr(28)~chr(29)~chr(30)~chr(31)~chr(34)
               ~"%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
               ~chr(128)~chr(129)~chr(130)~chr(131)~chr(132)~chr(133)~chr(134)~chr(135)~chr(136)~chr(137)~chr(138)
               ~chr(139)~chr(140)~chr(141)~chr(142)~chr(143)~chr(144)~chr(145)~chr(146)~chr(147)~chr(148)~chr(149)
               ~chr(150)~chr(151)~chr(152)~chr(153)~chr(154)~chr(155)~chr(156)~chr(157)~chr(158)~chr(159)~chr(160)
               ~chr(161)~chr(162)~chr(163)~chr(164)~chr(165)~chr(166)~chr(167)~chr(168)~chr(169)~chr(170)~chr(171)
               ~chr(172)~chr(173)~chr(174)~chr(175)~chr(176)~chr(177)~chr(178)~chr(179)~chr(180)~chr(181)~chr(182)
               ~chr(183)~chr(184)~chr(185)~chr(186)~chr(187)~chr(188)~chr(189)~chr(190)~chr(191)~chr(192)~chr(193)
               ~chr(194)~chr(195)~chr(196)~chr(197)~chr(198)~chr(199)~chr(200)~chr(201)~chr(202)~chr(203)~chr(204)
               ~chr(205)~chr(206)~chr(207)~chr(208)~chr(209)~chr(210)~chr(211)~chr(212)~chr(213)~chr(214)~chr(215)
               ~chr(216)~chr(217)~chr(218)~chr(219)~chr(220)~chr(221)~chr(222)~chr(223)~chr(224)~chr(225)~chr(226)
               ~chr(227)~chr(228)~chr(229)~chr(230)~chr(231)~chr(232)~chr(233)~chr(234)~chr(235)~chr(236)~chr(237)
               ~chr(238)~chr(239)~chr(240)~chr(241)~chr(242)~chr(243)~chr(244)~chr(245)~chr(246)~chr(247)~chr(248)
               ~chr(249)~chr(250)~chr(251)~chr(252)~chr(253)~chr(254)~chr(255),
    _base: 248,
    spaces: "                                  ",
    empty_encoding: chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1),
    encodeInt : func(num,length)
    {
        if (num == 0)
            return substr(BinaryAsciiTransfer.empty_encoding,0,length);
        var arr="";

        var negate=0;
        if (num < 0) {
            negate = 1;
            num = -num;
        }
        while (num > 0 and length > 0) {
            var num0 = num;
            num = (int)(num / BinaryAsciiTransfer._base);
            rem = num0-(num*BinaryAsciiTransfer._base);
            arr =substr(BinaryAsciiTransfer.alphabet, rem,1) ~ arr;
            length -= 1;
        }
        if (length>0)
            arr = substr(BinaryAsciiTransfer.spaces,0,length)~arr;
        if(negate) 
          arr = "-"~arr;
        return arr;
    },
    retval : {value:0, pos:0},
    decodeInt : func(str, length, pos)
    {
        var power = length-1;
        var negate = 0;
        BinaryAsciiTransfer.retval.value = 0;
        BinaryAsciiTransfer.retval.pos = pos;

        if (substr(str,BinaryAsciiTransfer.retval.pos,1)=="-") {
            negate=1;
            BinaryAsciiTransfer.retval.pos = BinaryAsciiTransfer.retval.pos+1;
        }

        while (length > 0 and power > 0) {
            var c = substr(str,BinaryAsciiTransfer.retval.pos,1);
            if (c != " ") break;
            power = power -1;
            length = length-1;
            BinaryAsciiTransfer.retval.pos = BinaryAsciiTransfer.retval.pos + 1;
        }
        while (length >= 0 and power >= 0) {
            var c = substr(str,BinaryAsciiTransfer.retval.pos,1);
            # spaces are used as padding so ignore them.
            if (c != " ") {
                var cc = find(c,BinaryAsciiTransfer.alphabet);
                if (cc < 0)
                  {
                      print("Emesary: BinaryAsciiTransfer.decodeInt: Bad encoding ");
                      return BinaryAsciiTransfer.retval;
                  }
               BinaryAsciiTransfer.retval.value += int(cc * math.exp(math.ln(BinaryAsciiTransfer._base) * power));
                power = power - 1;
            }
            length = length-1;
            BinaryAsciiTransfer.retval.pos = BinaryAsciiTransfer.retval.pos + 1;
        }
        if (negate)
              BinaryAsciiTransfer.retval.value = -BinaryAsciiTransfer.retval.value;
        return BinaryAsciiTransfer.retval;
    }
};

var TransferString = 
{
    MaxLength:16,
#
# just to pack a valid range and keep the lower and very upper control codes for seperators
# that way we don't need to do anything special to encode the string.
    getalphanumericchar : func(v)
    {
        if (find(v,BinaryAsciiTransfer.alphabet) > 0)#"-./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_abcdefghijklmnopqrstuvwxyz") > 0)
          return v;
        return nil;
    },
    encode : func(v)
    {
        if (v==nil)
          return "0";
        var l = size(v);
        if (l > TransferString.MaxLength)
            l = TransferString.MaxLength;
        var rv = "";
        var actual_len = 0;
        for(var ii = 0; ii < l; ii = ii + 1)
        {
            ev = TransferString.getalphanumericchar(substr(v,ii,1));
            if (ev != nil) {
                rv = rv ~ ev;
                actual_len = actual_len + 1;
            }
        }
        rv = BinaryAsciiTransfer.encodeInt(l,1) ~ rv;
        return rv;
    },
    decode : func(v,pos)
    {
        var dv = BinaryAsciiTransfer.decodeInt(v,1,pos);
        var length = dv.value;
        if (length == 0)
          return dv;
        var rv = substr(v,dv.pos,length);
        dv.pos = dv.pos + length;
        dv.value = rv;
        return dv;
    }
};

#
# encode an int into a specified number of characters.
var TransferInt = 
{
    encode : func(v, length)
    {
        return BinaryAsciiTransfer.encodeInt(v,length);
    },
    decode : func(v, length, pos)
    {
        return BinaryAsciiTransfer.decodeInt(v,length,pos);
    }
};

var TransferFixedDouble = 
{
    po2: [1.0,124.0,30752.0,7626496.0,1891371008.0,469060009984.0,116326882476032.0,28849066854055936.0], # needs to match powers of BinaryAsciiTransfer._base

    encode : func(v, length, factor)
    {
        var scale = int(me.po2[length] / factor);
        v = int(v * factor); 
        if (v < -me.po2[length]) v = -me.po2[length];
        else if (v > me.po2[length]) v = me.po2[length];
        return BinaryAsciiTransfer.encodeInt(int(v), length);
    },
    decode : func(v, length, factor, pos)
    {
       var scale = int(me.po2[length] / factor);
        var dv = BinaryAsciiTransfer.decodeInt(v, length, pos);
        dv.value = (int(dv.value)/factor);
        return dv;
    }
};

var TransferNorm = 
{
    powers: [1,10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0, 1000000000.0, 10000000000.0, 100000000000.0],
    po2: [1.0,123.0,30751.0,7626495.0,1891371007,469060009983,116326882476031,28849066854055935], # needs to match powers of BinaryAsciiTransfer._base

    encode : func(v, length)
    {
        v = v + 1;
        if(v>2)
            v=2;
        else if (v < 0) 
            v=0;
        return BinaryAsciiTransfer.encodeInt(int(v * me.po2[length]),length);
    },
    decode : func(v, length, pos)
    {
        dv = BinaryAsciiTransfer.decodeInt(v, length,pos);
        dv.value = (dv.value/me.po2[length]) - 1;
        return dv;
    }
};

var TransferByte = 
{
    encode : func(v)
    {
        return BinaryAsciiTransfer.encodeInt(v,1);
    },
    decode : func(v, pos)
    {
        return BinaryAsciiTransfer.decodeInt(v, 1,pos);
    }
};

var TransferCoord = 
{
# 28 bits = 268435456 (268 435 456)
# to transfer lat lon (360 degree range) 268435456/360=745654
# we could use different factors for lat lon due to the differing range, however
# this will be fine.
# 1 degree = 110574 meters;
    encode : func(v)
    {
        return  BinaryAsciiTransfer.encodeInt((v.lat()+90)*745654,5)
        ~ BinaryAsciiTransfer.encodeInt((v.lon()+180)*745654,5) 
        ~ TransferInt.encode(v.alt(), 3);
    },
    decode : func(v,pos)
    {
        var dv = BinaryAsciiTransfer.decodeInt(v,5,pos); 
        var lat = (dv.value / 745654)-90;
        dv = BinaryAsciiTransfer.decodeInt(v,5,dv.pos);
        var lon = (dv.value / 745654)-180;
        dv = TransferInt.decode(v, 3, dv.pos); 
        var alt =dv.value;

        dv.value = geo.Coord.new().set_latlon(lat, lon).set_alt(alt);
        return dv;
    }
};
#setprop("/sim/startup/terminal-ansi-colors",0);
#for(i=-1;i<=1;i+=0.1)
#print ("i ",i, " --> ", (TransferNorm.decode(TransferNorm.encode(i,2), 2,0)).value);
#debug.dump(TransferNorm.decode(TransferNorm.encode(-1,2), 2,0));
#debug.dump(TransferNorm.decode(TransferNorm.encode(0,2), 2,0));
#debug.dump(TransferNorm.decode(TransferNorm.encode(1,2), 2,0));
