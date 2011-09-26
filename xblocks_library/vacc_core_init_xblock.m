function vacc_core_init_xblock(varargin)

defaults = { ...
    'veclen', 32, ...
    'n_inputs', 1, ...
    'arith_type', 0, ...
    'bit_width_out', 32, ...
    'bin_pt_out', 17, ...
    'add_latency', 2, ...
    'bram_latency', 2, ...
    'mux_latency', 0, ...
    'bin_pt_in', 0, ...
    'use_dsp48', 1, ...
};

n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
veclen = get_var('veclen', 'defaults', defaults, varargin{:});
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:});
bit_width_out = get_var('bit_width_out', 'defaults', defaults, varargin{:});
bin_pt_out = get_var('bin_pt_out', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
mux_latency = get_var('mux_latency', 'defaults', defaults, varargin{:});
bin_pt_in = get_var('bin_pt_in', 'defaults', defaults, varargin{:});
use_dsp48 = get_var('use_dsp48', 'defaults', defaults, varargin{:});

% Hard coded add latency for dsp48 implementation mode
if use_dsp48
	add_latency = 2; 
end

%% inports
din = xblock_new_inputs('din', n_inputs, 1);
acc_en = xInport('acc_en');

%% outports
dout = xblock_new_outputs('dout', n_inputs, 1); 

%% diagram
del_bram_in = xblock_new_bus(n_inputs, 1);
din_del = xblock_new_bus(n_inputs, 1);

% adder
for k=1:n_inputs
    add_en_config.source = str2func('add_en_init_xblock');
    add_en_config.name = ['adder_with_enable_', num2str(k)];
    add_en_params = {'bin_pt_din0', bin_pt_in, 'bin_pt_din1', bin_pt_in, ...
        'bit_width_out', bit_width_out, 'bin_pt_out', bin_pt_out, 'arith_type', arith_type, ...
        'use_dsp48', use_dsp48, 'add_latency', add_latency, 'mux_latency', mux_latency};
    xBlock( add_en_config, add_en_params, {din{k,1}, din_del{k,1}, acc_en}, {del_bram_in{k,1}} );

    dout{k,1}.bind( del_bram_in{k,1} );
end

% memory
delay_bram_config.source = str2func('delay_bram_init_xblock');
delay_bram_config.name = ['acc_mem',num2str(k)];
bram_delay = veclen-add_latency-mux_latency;
delay_bram_params = {'latency', bram_delay, 'bram_latency', bram_latency, ...
    'n_inputs', n_inputs};
xBlock( delay_bram_config, delay_bram_params, {del_bram_in{:,1}}, {din_del{:,1}} );
    

end

