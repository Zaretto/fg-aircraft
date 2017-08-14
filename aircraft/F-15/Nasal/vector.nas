var Math = {
    #
    # Author: Nikolai V. Chr.
    #
    # Version 1.3
    #
    # When doing euler to cartesian: +x = forw, +y = right, +z = up.
    #
    clamp: func(v, min, max) { v < min ? min : v > max ? max : v },

    angleBetweenVectors: func (a,b) {
        a = me.normalize(a);
        b = me.normalize(b);
        me.value = me.clamp((me.dotProduct(a,b)/me.magnitudeVector(a))/me.magnitudeVector(b),-1,1);#just to be safe in case some floating point error makes it out of bounds
        return R2D * math.acos(me.value);
    },

    magnitudeVector: func (a) {
        return math.sqrt(math.pow(a[0],2)+math.pow(a[1],2)+math.pow(a[2],2));
    },

    dotProduct: func (a,b) {
        return a[0]*b[0]+a[1]*b[1]+a[2]*b[2];
    },

    eulerToCartesian3Z: func (heading_deg, pitch_deg, roll_deg) {
        me.yaw   = heading_deg * D2R;
        me.pitch = pitch_deg   * D2R;
        me.roll  = roll_deg    * D2R;
        me.x = -math.cos(me.yaw)*math.sin(me.pitch)*math.cos(me.roll) + math.sin(me.yaw)*math.sin(me.roll);
        me.y = -math.sin(me.yaw)*math.sin(me.pitch)*math.cos(me.roll) - math.cos(me.yaw)*math.sin(me.roll);
        me.z =  math.cos(me.pitch)*math.cos(me.roll);#roll changed from sin to cos, since the rotation matrix is wrong
        return [me.x,me.y,me.z];
    },

    eulerToCartesian3X: func (heading_deg, pitch_deg, roll_deg) {
        me.yaw   = heading_deg * D2R;
        me.pitch = pitch_deg   * D2R;
        me.roll  = roll_deg    * D2R;
        me.x = math.cos(me.yaw)*math.cos(me.pitch);
        me.y = math.sin(me.yaw)*math.cos(me.pitch);
        me.z = math.sin(me.pitch);
        return [me.x,me.y,me.z];
    },

    eulerToCartesian3Y: func (heading_deg, pitch_deg, roll_deg) {#not used but could be handy for something else
        me.yaw   = heading_deg * D2R;
        me.pitch = pitch_deg   * D2R;
        me.roll  = roll_deg    * D2R;
        me.x = -math.cos(me.yaw)*math.sin(me.pitch)*math.sin(me.roll) - math.sin(me.yaw)*math.cos(me.roll);
        me.y = -math.sin(me.yaw)*math.sin(me.pitch)*math.sin(me.roll) + math.cos(me.yaw)*math.cos(me.roll);
        me.z =  math.cos(me.pitch)*math.sin(me.roll);
        return [me.x,me.y,me.z];
    },

    eulerToCartesian2: func (heading_deg, pitch_deg) {
        me.yaw   = heading_deg * D2R;
        me.pitch = pitch_deg   * D2R;
        me.x = math.cos(me.pitch) * math.cos(me.yaw);
        me.y = math.cos(me.pitch) * math.sin(me.yaw);
        me.z = math.sin(me.pitch);
        return [me.x,me.y,me.z];
    },

    getPitch: func (coord1, coord2) {
      #pitch from coord1 to coord2 in degrees (takes curvature of earth into effect.)
      if (coord1.lat() == coord2.lat() and coord1.lon() == coord2.lon()) {
        if (coord2.alt() > coord1.alt()) {
          return 90;
        } elsif (coord2.alt() < coord1.alt()) {
          return -90;
        } else {
          return 0;
        }
      }
      if (coord1.alt() != coord2.alt()) {
        me.d12 = coord1.direct_distance_to(coord2);
        me.coord3 = geo.Coord.new(coord1);
        me.coord3.set_alt(coord1.alt()-me.d12*0.5);# this will increase the area of the triangle so that rounding errors dont get in the way.
        me.d13 = coord1.alt()-me.coord3.alt();        
        if (me.d12 == 0) {
            # on top of each other, maybe rounding error..
            return 0;
        }
        me.d32 = me.coord3.direct_distance_to(coord2);
        if (math.abs(me.d13)+me.d32 < me.d12) {
            # rounding errors somewhere..one triangle side is longer than other 2 sides combined.
            return 0;
        }
        # standard formula for a triangle where all 3 side lengths are known:
        me.len = (math.pow(me.d12, 2)+math.pow(me.d13,2)-math.pow(me.d32, 2))/(2 * me.d12 * math.abs(me.d13));
        if (me.len < -1 or me.len > 1) {
            # something went wrong, maybe rounding error..
            return 0;
        }
        me.angle = R2D * math.acos(me.len);
        me.pitch = -1* (90 - me.angle);
        #printf("d12 %.4f  d32 %.4f  d13 %.4f len %.4f pitch %.4f angle %.4f", me.d12, me.d32, me.d13, me.len, me.pitch, me.angle);
        return me.pitch;
      } else {
        # same altitude
        me.nc = geo.Coord.new();
        me.nc.set_xyz(0,0,0);        # center of earth
        me.radiusEarth = coord1.direct_distance_to(me.nc);# current distance to earth center
        me.d12 = coord1.direct_distance_to(coord2);
        # standard formula for a triangle where all 3 side lengths are known:
        me.len = (math.pow(me.d12, 2)+math.pow(me.radiusEarth,2)-math.pow(me.radiusEarth, 2))/(2 * me.d12 * me.radiusEarth);
        if (me.len < -1 or me.len > 1) {
            # something went wrong, maybe rounding error..
            return 0;
        }
        me.angle = R2D * math.acos(me.len);
        me.pitch = -1* (90 - me.angle);
        return me.pitch;
      }
    },

    projVectorOnPlane: func (planeNormal, vector) {
      return me.minus(vector, me.product(me.dotProduct(vector,planeNormal)/math.pow(me.magnitudeVector(planeNormal),2), planeNormal));
    },

    minus: func (a, b) {
      return [a[0]-b[0], a[1]-b[1], a[2]-b[2]];
    },

    plus: func (a, b) {
      return [a[0]+b[0], a[1]+b[1], a[2]+b[2]];
    },

    product: func (scalar, vector) {
      return [scalar*vector[0], scalar*vector[1], scalar*vector[2]]
    },

    format: func (v) {
      return sprintf("(%.1f, %.1f, %.1f)",v[0],v[1],v[2]);
    },

    normalize: func (v) {
      me.mag = me.magnitudeVector(v);
      return [v[0]/me.mag, v[1]/me.mag, v[2]/me.mag];
    },
};

# Fix for geo.Coord:
geo.Coord.set_x = func(x) { me._cupdate(); me._pdirty = 1; me._x = x; me };
geo.Coord.set_y = func(y) { me._cupdate(); me._pdirty = 1; me._y = y; me };
geo.Coord.set_z = func(z) { me._cupdate(); me._pdirty = 1; me._z = z; me };
geo.Coord.set_lat = func(lat) { me._pupdate(); me._cdirty = 1; me._lat = lat * D2R; me };
geo.Coord.set_lon = func(lon) { me._pupdate(); me._cdirty = 1; me._lon = lon * D2R; me };
geo.Coord.set_alt = func(alt) { me._pupdate(); me._cdirty = 1; me._alt = alt; me };
geo.Coord.apply_course_distance2 = func(course, dist) {# this method in geo is not bad, just wanted to see if this way of doing it worked better.
        me._pupdate();
        course *= D2R;
        var nc = geo.Coord.new();
        nc.set_xyz(0,0,0);        # center of earth
        dist /= me.direct_distance_to(nc);# current distance to earth center
        
        if (dist < 0.0) {
          dist = abs(dist);
          course = course - math.pi;        
        }
        
        me._lat2 = math.asin(math.sin(me._lat) * math.cos(dist) + math.cos(me._lat) * math.sin(dist) * math.cos(course));

        me._lon = me._lon + math.atan2(math.sin(course)*math.sin(dist)*math.cos(me._lat),math.cos(dist)-math.sin(me._lat)*math.sin(me._lat2));

        while (me._lon <= -math.pi)
            me._lon += math.pi*2;
        while (me._lon > math.pi)
            me._lon -= math.pi*2;

        me._lat = me._lat2;
        me._cdirty = 1;
        me;
    };