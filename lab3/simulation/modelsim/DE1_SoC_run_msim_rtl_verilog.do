transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/regfile.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/memory.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/code_memory.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/register_addr.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/conditional_check.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/execution.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/update.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/pc_inc.sv}
vlog -sv -work work +incdir+C:/Users/Jiarong\ Qian/Documents/Course\ Materials/wi2020/ee469/lab3 {C:/Users/Jiarong Qian/Documents/Course Materials/wi2020/ee469/lab3/cpu.sv}

