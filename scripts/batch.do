onerror {quit -force -code 1}
# Return control to the script after a stop/break. The shell also requires
# the exact PASS marker and rejects simulator Error/Fatal messages.
onbreak {resume}
# Wave logging is optional: lack of visible objects must not prevent run.
if {[catch {log -r /*} log_message]} {
    puts "WAVEFORM WARNING: logging unavailable: $log_message"
}
run -all
# Save the functional covergroup database and the simulator's bin report.
# run.sh sets this variable only for the class-based tests.
if {[info exists env(FIFO_DV_COVERAGE_DIR)] && $env(FIFO_DV_COVERAGE_DIR) ne ""} {
    coverage save -cvg -assert -directive -testname $env(FIFO_DV_TEST_NAME) [file join $env(FIFO_DV_COVERAGE_DIR) coverage.ucdb]
    coverage report -cvg -assert -directive -details -output [file join $env(FIFO_DV_COVERAGE_DIR) coverage-tool.txt]
}
quit -force -code 0
