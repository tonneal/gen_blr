#source apply_ps.tcl
set prj_name "myprj"
set bd_name "myprj_bd"



set compile_order "sources_1"

set output_hdf "output.hdf"

# 默认配置文件名
set ps7_config_file "processor_config.tcl"

set origin_dir "."
set configs_dir ${origin_dir}/ps7_configs
set output_dir ${origin_dir}/output
set build_dir ${origin_dir}/build
set bd_dir ${build_dir}/${prj_name}.srcs/${compile_order}/bd/${bd_name}
set hdl_dir ${bd_dir}/hdl
set sdk_dir ${build_dir}/${prj_name}.sdk
set ps7_dir ${bd_dir}/ip/${bd_name}_processing_system7_0_0

set i 0
while {$i < $argc} {
	puts $i
#lindex 命令用于取出list中指定索引的参数
    set arg [lindex $argv $i]
    #puts "$arg"
    set ps7_config_file ${arg}_config.tcl
    set soc_config_file ${arg}_soc.tcl
#incr 命令用于对变量进行加操作
    incr i 1
}


puts $ps7_config_file
puts $soc_config_file

set soc_name "none"
if { [file exists ${configs_dir}/${soc_config_file} ] } { 
  source ${configs_dir}/${soc_config_file}
}
if { ${soc_name} == "none"} {
  puts "ERROR SOC 未设置"
  错误返回
}
puts ${soc_name}

# Create Vivado Project
create_project -force $prj_name $build_dir -part ${soc_name}
#create_project -force $prj_name $build_dir
# Create Block Design
create_bd_design $bd_name

update_compile_order -fileset ${compile_order}

# Add ZYNQ7 IP
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Apply ZYNQ7 IP from config file
source ${configs_dir}/${ps7_config_file}
set presets [apply_preset 0]

foreach {k v} $presets {
  if {![info exists preset_list]} {
    set preset_list [dict create $k $v]
  } else {
    dict set preset_list $k $v
  }
}
set_property -dict $preset_list [get_bd_cells processing_system7_0]

# Run Block Automation
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

# Manual Connect 
#create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr
#create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 fixed_io
#connect_bd_intf_net [get_bd_intf_ports ddr] [get_bd_intf_pins processing_system7_0/DDR]
#connect_bd_intf_net [get_bd_intf_ports fixed_io] [get_bd_intf_pins processing_system7_0/FIXED_IO]

# Connect FCLK_CLK0
#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK]
#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP1_ACLK]

connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP*_ACLK]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP*_ACLK]

# Generate Output Products
#-------------------
export_ip_user_files -of_objects [get_files ${bd_dir}/${bd_name}.bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ${bd_dir}/${bd_name}.bd]
#launch_runs -jobs 2 ${bd_name}_processing_system7_0_0_synth_1
#export_simulation -of_objects [get_files ${bd_dir}/${bd_name}.bd] -directory /home/oneal/vivado/prj2/project_1/project_1.ip_user_files/sim_scripts -ip_user_files_dir /home/oneal/vivado/prj2/project_1/project_1.ip_user_files -ipstatic_source_dir /home/oneal/vivado/prj2/project_1/project_1.ip_user_files/ipstatic -lib_map_path [list {modelsim=/home/oneal/vivado/prj2/project_1/project_1.cache/compile_simlib/modelsim} {questa=/home/oneal/vivado/prj2/project_1/project_1.cache/compile_simlib/questa} {ies=/home/oneal/vivado/prj2/project_1/project_1.cache/compile_simlib/ies} {vcs=/home/oneal/vivado/prj2/project_1/project_1.cache/compile_simlib/vcs} {riviera=/home/oneal/vivado/prj2/project_1/project_1.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
#-------------------


# Create wrapper
#-------------------
make_wrapper -files [get_files ${bd_dir}/${bd_name}.bd] -top
add_files -norecurse ${hdl_dir}/${bd_name}_wrapper.v
update_compile_order -fileset ${compile_order}
#-------------------

generate_target all [get_files ${bd_dir}/${bd_name}.bd]
regenerate_bd_layout
save_bd_design
validate_bd_design

# Export Hardware
#-------------------
if { [file exists ${output_dir} ] } { file delete -force ${output_dir}/ }
file mkdir ${output_dir}

if { [file exists ${sdk_dir} ] } { file delete ${sdk_dir} }
file mkdir ${sdk_dir}
write_hwdef -force  -file ${sdk_dir}/output.hdf
file copy ${sdk_dir}/output.hdf ${output_dir}/output.hdf
#-------------------

## Create wrapper
##make_wrapper -files [get_files ${bd_dir}/${bd_name}.bd] -top
##add_files -norecurse ${hdl_dir}/${bd_name}_wrapper.v
##update_compile_order -fileset ${compile_order}
#
## Generate output product
#generate_target all [get_files ${bd_dir}/${bd_name}.bd]
#
###
#regenerate_bd_layout
#save_bd_design
#validate_bd_design
###

file copy ${origin_dir}/zed_temp/drivers.txt    ${output_dir}/
file copy ${origin_dir}/zed_temp/inbyte.c       ${output_dir}/
file copy ${origin_dir}/zed_temp/outbyte.c      ${output_dir}/
file copy ${origin_dir}/zed_temp/xparameters.h  ${output_dir}/

file copy ${ps7_dir}/ps7_init.c ${output_dir}/
file copy ${ps7_dir}/ps7_init.h ${output_dir}/

file copy ${ps7_dir}/ps7_parameters.xml ${output_dir}/



#if { [file exists ${sdk_dir} ] } { file delete ${sdk_dir} }
#file mkdir ${sdk_dir}
#write_hwdef -force  -file ${sdk_dir}/output.hdf
#file copy ${sdk_dir}/output.hdf ${output_dir}/output.hdf
