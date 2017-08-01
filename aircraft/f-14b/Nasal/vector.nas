var Math = {
    #
    # Author: Nikolai V. Chr.
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
      #pitch from c1 to c2 in degrees (takes curvature of earth into effect.)
      me.coord3 = geo.Coord.new(coord1);
      me.coord3.set_alt(coord2.alt());
      me.d12 = coord1.direct_distance_to(coord2);
      if (me.d12 > 0.1 and coord1.alt() != coord2.alt()) {# not sure how to cope with same altitudes.
        me.d32 = me.coord3.direct_distance_to(coord2);
        me.altD = coord1.alt()-me.coord3.alt();
        me.y = R2D * math.acos((math.pow(me.d12, 2)+math.pow(me.altD,2)-math.pow(me.d32, 2))/(2 * me.d12 * me.altD));
        me.pitch = -1* (90 - me.y);
        return me.pitch;
      } else {
        return 0;
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