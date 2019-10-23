#include "ruby.h"
#include "ruby/debug.h"
#include "monitor.h"
#include "normalize.h"
#include "breakpoints.h"
#include "frame.h"

static VALUE m_Readapt;

void Init_readapt()
{
	m_Readapt = rb_define_module("Readapt");

	initialize_normalize(m_Readapt);
	initialize_breakpoints(m_Readapt);
	initialize_frame(m_Readapt);
	initialize_monitor(m_Readapt);
}
