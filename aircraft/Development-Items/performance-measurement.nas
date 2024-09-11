# used to measure how the simulation is performing based on
# frame rate over a period using an average and a filter to smooth
# out the changes.

if (aircraft["tt"]) aircraft.tt.stop();

var PerformanceMeasurement = {
    new : func {
        return {
            parents: [PerformanceMeasurement],
            lp : aircraft.lowpass.new(0.1),
            frame_count_node : props.globals.getNode("/sim/frame-number"),
            frame_count : getprop("/sim/frame-number"),
            start_time : systime(),
            frame_rate : 30,
        };
    },
     update: func {
        me.delta_seconds =  systime() - me.start_time;
        me.frame_count_delta = me.frame_count_node.getValue() - me.frame_count;
        me.frame_rate =  me.frame_count_delta / me.delta_seconds;
        me.elapsed_seconds= systime();
        me.filtered_frame_rate_worst = (int)(me.lp.filter(me.frame_rate));

        printf("%5.1f: rate = %5.1f  dS=%5.2f, filt=%5.1f",
                me.elapsed_seconds,  
                me.frame_rate, 
                me.delta_seconds,
                me.filtered_frame_rate_worst);

        if (me.delta_seconds > 5){
            me.start_time = systime();
            me.frame_count = me.frame_count_node.getValue();
        }
     },
     start : func {
        me.timer = maketimer(2, me, func { me.update() });
        me.timer.simulatedTime = 0;
        aircraft["tt"] = me.timer;
        me.timer.start();
        return me;
     }
};


pt  =  PerformanceMeasurement.new().start();
debug.dump(pt);
