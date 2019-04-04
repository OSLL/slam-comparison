#!/usr/bin/env python

import rospy
import tf
import time

if __name__ == '__main__':
    rospy.init_node('pose_logger', anonymous=True, log_level=rospy.INFO)

    target_frame = rospy.get_param('~target_frame', 'base_link2')
    base_frame = rospy.get_param('~base_frame', 'odom_combined2')
    output_file = rospy.get_param('~output_file', 'out_traj.txt')
    
    output = open(output_file, 'w')
    
    listener = tf.TransformListener()
    rate = rospy.Rate(4)
    while True:
        #listener.waitForTransform(target_frame, base_frame, rospy.Time(), rospy.Duration(10000))
        try:
            time = listener.getLatestCommonTime(target_frame, base_frame)    
            (t, q) = listener.lookupTransform(target_frame, base_frame, time)
            output.write("%d.%d %f %f 0.0 %f %f %f %f\n" % (time.secs, time.nsecs, t[0], t[1], q[0], q[1], q[2], q[3]))
            rate.sleep()
        except Exception:
            rate.sleep()

