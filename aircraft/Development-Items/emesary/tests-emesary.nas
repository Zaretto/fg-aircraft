 #---------------------------------------------------------------------------
 #
 #	Title                : EMESARY tests
 #
 #	File Type            : Implementation File
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 29 January 2016
 #
 #  Copyright © 2016 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

print("Emesary tests");

var TestFailCount = 0;
var TestSuccessCount = 0;

var TestNotification =
{
    new: func(_value)
    {
        var new_class = emesary.Notification.new("TestNotification", _value);
        return new_class;
    },
};
var TestNotProcessedNotification =
{
    new: func(_value)
    {
        var new_class = emesary.Notification.new("TestNotProcessedNotification", _value);
        return new_class;
    },
};
var RadarReturnNotification =
{
    new: func(_value, _x, _y, _z)
    {
        var new_class = emesary.Notification.new("RadarReturnNotification", _value);
        new_class.x = _x;
        new_class.y = _y;
        new_class.z = _z;
        return new_class;
    },
};

var TestRecipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident);
        new_class.count = 0;
        new_class.Receive = func(notification)
        {
            if (notification.Type == "TestNotification")
            {
                me.count = me.count + 1;
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};

var TestRadarRecipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident);
        new_class.Receive = func(notification)
        {
            if (notification.Type == "RadarReturnNotification")
            {
                print(" :: Test recipient ",me.Ident, " recv:",notification.Type," ",notification.Value);
                print(" ::   ",notification.x, " ", notification.y, " ", notification.z);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};
var PerformTest = func(tid, t)
{
    if (t())
    {
        TestSuccessCount = TestSuccessCount + 1;
        print("  Test [Pass] :",tid);
    }
    else
    {
        TestFailCount = TestFailCount + 1;
        print("  Test [Fail] :",tid);
    }
}
var tt = TestRecipient.new("tt recipient");
var tt1 = TestRecipient.new("tt1 recipient1");
var tt3 = TestRecipient.new("tt3 recipient3");
var tt2 = TestRadarRecipient.new("tt2: Radar Test recipient2");

PerformTest("Create Notification", 
            func 
            {
                var tn = TestNotification.new("Test notification"); 
                return tn.Type == "TestNotification" and tn.Value == "Test notification";
            });

PerformTest("Register tt", 
            func 
            {
                emesary.GlobalTransmitter.Register(tt);
                return emesary.GlobalTransmitter.RecipientCount() == 1; 
            });
PerformTest("Register tt1", 
            func 
            {
                emesary.GlobalTransmitter.Register(tt1);
                return emesary.GlobalTransmitter.RecipientCount() == 2; 
            });
PerformTest("Register tt2", 
            func 
            {
                emesary.GlobalTransmitter.Register(tt2);
                return emesary.GlobalTransmitter.RecipientCount() == 3; 
            });
PerformTest("Register tt3", 
            func 
            {
                emesary.GlobalTransmitter.Register(tt3);
                return emesary.GlobalTransmitter.RecipientCount() == 4; 
            });

PerformTest("Notify", 
            func
            {
                var rv = emesary.GlobalTransmitter.NotifyAll(TestNotification.new("Test notification"));
                return !emesary.Transmitter.IsFailed(rv) and rv != emesary.Transmitter.ReceiptStatus_NotProcessed and tt.count == 1; 
            });

PerformTest("DeRegister tt1", 
            func
            {
                emesary.GlobalTransmitter.DeRegister(tt1);
                return emesary.GlobalTransmitter.RecipientCount() == 3; 
            });

tt1_count = tt1.count;
PerformTest("NotifyAfterDeregister", 
            func
            {
                emesary.GlobalTransmitter.NotifyAll(TestNotification.new("Test notification"));
                return tt1.count == tt1_count;
            });

tt.Active = 0;
tt_count = tt.count;

PerformTest("Recipient.Active", 
            func
            {
                var rv = emesary.GlobalTransmitter.NotifyAll(TestNotification.new("Test notification"));
                return !emesary.Transmitter.IsFailed(rv) and rv != emesary.Transmitter.ReceiptStatus_NotProcessed and tt.count == tt_count; 
            });


PerformTest("Test Not Processed Notification", 
            func
            {
                var rv = emesary.GlobalTransmitter.NotifyAll(TestNotProcessedNotification.new("Not Processed"));
                return rv == emesary.Transmitter.ReceiptStatus_NotProcessed; 
            });


emesary.GlobalTransmitter.NotifyAll(RadarReturnNotification.new("Radar notification", "x0","y0","z0"));

if (!TestFailCount)
    print("Emesary: All ",TestSuccessCount," tests passed\n");
else
    print("Emesary: ERROR: Tests completed: ",TestFailCount," failed and ",TestSuccessCount," passed\n");

