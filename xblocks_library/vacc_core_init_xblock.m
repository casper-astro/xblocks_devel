function vacc_core_init_xblock(varargin)

defaults = { ...
    'veclen', 32, ...
    'arith_type', 1, ...
    'bit_width_out', 32, ...
    'bin_pt_out', 7, ...
    'add_latency', 2, ...
    'bram_latency', 2, ...
    'mux_latency', 0, ...
    'in_bin_pt', 0, ...
    'use_dsp48', 1, ...
};

veclen = get_var('veclen', 'defaults', defaults, varargin{:});
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:});
bit_width_out = get_var('bit_width_out', 'defaults', defaults, varargin{:});
bin_pt_out = get_var('bin_pt_out', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
mux_latency = get_var('mux_latency', 'defaults', defaults, varargin{:});
in_bin_pt = get_var('in_bin_pt', 'defaults', defaults, varargin{:});
use_dsp48 = get_var('use_dsp48', 'defaults', defaults, varargin{:});

% veclen, arith_type, bit_width_out, bin_pt_out, add_latency, bram_latency, mux_latency, in_bin_pt)
%% inports
din = xInport('din');
acc_en = xInport('acc_en');

%% outports
dout = xOutport('dout');

%% diagram
del_bram_in = xSignal;
din_del = xSignal;

% adder
add_en_config.source = str2func('add_en_init_xblock');
add_en_config.name = 'adder_with_enable';
add_en_params = {'use_dsp48', use_dsp48};
xBlock( add_en_config, add_en_params, {din, acc_en, din_del}, {del_bram_in} );

% memory
delay_bram_config.source = str2func('delay_bram_init_xblock');
delay_bram_config.name = 'acc_mem';
delay_bram_params = {};
xBlock( delay_bram_config, delay_bram_params, {del_bram_in}, {din_del} );
dout.bind( del_bram_in );

end

