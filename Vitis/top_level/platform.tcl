# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\taise\Desktop\Homework\SEM_3\ECE_385\Image_Processor\Vitis\top_level\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\taise\Desktop\Homework\SEM_3\ECE_385\Image_Processor\Vitis\top_level\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {top_level}\
-hw {C:\Users\taise\Desktop\Homework\SEM_3\ECE_385\Image_Processor\Vivado\top_level.xsa}\
-out {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vitis}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {dhrystone}
platform generate -domains 
platform active {top_level}
platform generate -quick
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform clean
platform generate
platform active {top_level}
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform generate -domains 
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform generate -domains 
platform active {top_level}
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform generate -domains 
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform generate -domains 
platform active {top_level}
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform generate -domains 
platform active {top_level}
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform generate -domains 
platform active {top_level}
platform config -updatehw {C:/Users/taise/Desktop/Homework/SEM_3/ECE_385/Image_Processor/Vivado/top_level.xsa}
platform generate -domains 
