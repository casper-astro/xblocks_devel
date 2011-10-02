function spect_power( blk, varargin )

defaults = { ...
	'bitwidth', 18, ...
	'add_latency', 2, ...
	'mult_latency', 3, ...
	'impl_mode', 'dsp48e', ...
	'n_inputs', 4, ...
};
bitwidth = get_var('bitwidth', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
impl_mode = get_var('impl_mode', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});


%SPECT_POWER Generates a block which computes the magnitude squared 
% of a n_inputs complex numbers

sync_in = xInport('sync_in');
sync_out = xOutport('sync_out');
data_inports = {};
data_outports = {};
for k = 0:n_inputs-1
   data_inports{k+1} = xInport(['din_', num2str(k)]);
   data_outports{k+1} = xOutport(['dout_', num2str(k)]);
end

sync_delay = 0;
if strcmp(impl_mode, 'dsp48e')
    sync_delay = 4;
    for k=1:n_inputs
        power_dsp48e_config.source = str2func('power_dsp48e_init_xblock');
        power_dsp48e_config.name = ['power', num2str(k)];
        power_block_k = xBlock( power_dsp48e_config, ...
            {bitwidth}, ...
            {data_inports{k} }, ...
            {data_outports{k}});
    end   
elseif strcmp(impl_mode, 'behavioral')
    sync_delay = add_latency + mult_latency;    
    for k=1:n_inputs
        power_config.source = str2func('power_behav_init_xblock');
        power_config.name = ['power', num2str(k)];
        power_block_k = xBlock( power_config, ...
            {bitwidth, add_latency, mult_latency}, ...
            {data_inports{k} }, ...
            {data_outports{k}});        
    end    
end
sync_delay_block = xBlock( struct('source', 'Delay', 'name', 'sync_delay'), ...
    struct('latency', sync_delay), ...
    {sync_in}, ...
    {sync_out});


end

