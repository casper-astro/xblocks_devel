function reorder_init(blk, varargin)
% Valid varnames for this block are:
% map = The desired output order.
% map_latency = The latency of a map block.
% bram_latency = The latency of a BRAM block.
% n_inputs = The number of parallel inputs to be reordered.
% double_buffer = Whether to use two buffers to reorder data (instead of
%                 doing it in-place).
% bram_map = Whether to use BlockRAM for address mapping.

% Declare any default values for arguments you might like.
defaults = {'map_latency', 0, 'bram_latency', 2, 'n_inputs', 1, 'double_buffer', 0, 'bram_map', 'off'};

map = get_var('map', 'defaults', defaults, varargin{:});
map_latency = get_var('map_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
double_buffer = get_var('double_buffer', 'defaults', defaults, varargin{:});
bram_map = get_var('bram_map', 'defaults', defaults, varargin{:});

if n_inputs < 1
    error('Number of inputs cannot be less than 1.');
end

map_length = length(map);
map_bits = ceil(log2(map_length));
order = compute_order(map);
order_bits = ceil(log2(order));

if (strcmp('on',bram_map))
    map_memory_type = 'Block RAM';
else
    map_memory_type = 'Distributed memory';
end

if (double_buffer < 0 || double_buffer > 1) ,
	disp('Double Buffer must be 0 or 1');
	error('Double Buffer must be 0 or 1');
end

% At some point, when Xilinx supports muxes wider than 16, this can be
% fixed.
if order > 16 && double_buffer == 0,
    error('Reorder can only support a map orders <= 16 in single buffer mode.');
end
% Non-power-of-two maps could be supported by adding a counter an a
% comparitor, rather than grouping the map and address count into one
% counter.
if 2^map_bits ~= map_length,
    error('Reorder currently only supports maps which are 2^? long.')
end

sync = xInport('sync')
en = xInport('en')
sync_out = xOutport('sync_out')
valid = xOutport('valid')

sync_delay_out = xSignal;
sync_delay_en_out = xSignal;
delay_we_out = xSignal;
pre_sync_delay_out = xSignal;
sync_delay_en_out = xSignal;

% Add Static Blocks
if double_buffer == 1,
    order = 2;
end
pre_sync_delay = xBlock( struct( 'name', 'pre_sync_delay', 'source', 'Delay'), ...
	{'Position', [ 55   159    75   201], 'latency', (order-1)*map_latency}, {sync}, {pre_sync_delay_out});
sync_delay_en = xBlock( struct( 'name', 'sync_delay_en', 'source', str2func('sync_delay_en_init_xblock')), ...
	{map_length}, {pre_sync_delay_out, en}, {sync_delay_en_out});    	
	
post_sync_delay = xBlock( struct('name', 'post_sync_delay', 'source', 'Delay'), ...
    {'Position', [135   159   155   201], 'latency', (bram_latency+1+double_buffer)}, ...
    {sync_delay_en_out}, {sync_out});
delay_we = xBlock( struct('name', 'delay_we', 'source', 'Delay'), ...
    {'Position', [305   115    345   135], 'latency', ((order-1)*map_latency)}, {en}, {delay_we_out} );
    
delay_valid = xBlock( struct('name', 'delay_valid', 'source', 'Delay'), ...
    {'Position', [495    13    525    27], 'latency', (bram_latency+1+double_buffer)}, {delay_we_out}, {valid} );


din_ports = {};
dout_ports = {};
for i=1:n_inputs,
	% Ports
	din_ports{i} = xInport(['din',tostring(i-1)]);
	dout_ports{i} = xOutport(['dout',tostring(i-1)]);
end


% Special case for reorder of order 1 (just delay)
if order == 1,
	for i=1:n_inputs,
        % Delays
        delay_din_bram_in = xSignal;
        delay_din = xBlock( struct('source', 'Delay', 'name', 'delay_din'), ...
            {'Position', [550    80*i    590    80*i+20], 'latency', ((order-1)*map_latency+1)}, ...
            { din_ports{i} }, { delay_din_bram_in });
        delay_din_bram = xBlock( struct('source', 'casper_library_delays/delay_bram_en_plus', 'name', ['delay_din_bram',tostring(i-1)]), ...
            {'Position', [620    80*i    660    80*i+20], 'DelayLen', length(map), 'bram_latency', bram_latency}, ...
            {delay_din_bram_in, delay_we_out}, {dout_ports{i}});
    end
    
% Case for order != 1, single-buffered
elseif double_buffer == 0,
	counter_out = xSignal;
    xBlock( struct('name', 'Counter', 'source', 'Counter'), ...
        struct('Position', [95    56   145   109],'n_bits', (map_bits + order_bits), 'cnt_type', 'Count Limited', ...
        'arith_type', 'Unsigned', 'cnt_to', (2^map_bits * order - 1), ...
        'en', 'on', 'rst', 'on'), ...
        {sync}, {counter_out});
    xBlock( struct('name', 'Slice1', 'source', 'xbsIndex_r4/Slice', ...
        struct( 'Position', [170    37   200    53], 'mode', 'Upper Bit Location + Width', ...
        'nbits', (order_bits)) );
    xBlock( struct('name', 'Slice2', 'source', 'Slice'), ...
        struct('Position', [170    77   200    93], 'mode', 'Lower Bit Location + Width', ...
        'nbits', (map_bits)) );
    xBlock( struct('name', 'Mux', 'source', 'Mux'), ...
        struct('Position', [415    34   440    62+20*order], 'inputs', (order), 'latency', 1) );
    xBlock( struct('name', 'delay_sel', 'source', 'Delay'), ...
        struct('Position', [305    37    345    53], 'latency', ((order-1)*map_latency)) );
    xBlock( struct('name', 'delay_d0', 'source', 'Delay'), ...
        struct('Position', [305    77    345    93], 'latency', ((order-1)*map_latency)) );


    % Add Dynamic Ports and Blocks
    for i=1:n_inputs,
        % BRAMS
        reuse_block(blk, ['delay_din',tostring(i-1)], 'xbsIndex_r4/Delay', ...
            'Position', [550    80*i    590    80*i+20], 'latency', tostring((order-1)*map_latency+1));
        reuse_block(blk, ['bram',tostring(i-1)], 'xbsIndex_r4/Single Port RAM', ...
            'Position', [615    80*i-17   680   80*i+37], 'depth', tostring(2^map_bits), ...
            'write_mode', 'Read Before Write', 'latency', tostring(bram_latency));
    end

    % Add Maps
    for i=1:order-1,
        mapname = ['map', tostring(i)];
        reuse_block(blk, mapname, 'xbsIndex_r4/ROM', ...
            'depth', tostring(map_length), 'initVector', 'map', 'latency', tostring(map_latency), ...
            'arith_type', 'Unsigned', 'n_bits', tostring(map_bits), 'bin_pt', '0', ...
            'distributed_mem', map_memory_type, 'Position', [230  125+50*i   270    145+50*i]);
        reuse_block(blk, ['delay_',mapname], 'xbsIndex_r4/Delay', ...
            'Position', [305   125+50*i    345   145+50*i], 'latency', [tostring(order-(i+1)),'*map_latency']);
    end

    % Add static wires
    add_line(blk, 'sync/1', 'Counter/1');
    add_line(blk, 'en/1', 'Counter/2');
    add_line(blk, 'Counter/1', 'Slice1/1');
    add_line(blk, 'Counter/1', 'Slice2/1');
    add_line(blk, 'Slice1/1', 'delay_sel/1');
    add_line(blk, 'delay_sel/1', 'Mux/1');
    add_line(blk, 'Slice2/1', 'delay_d0/1');
    add_line(blk, 'delay_d0/1', 'Mux/2');
    add_line(blk, 'sync/1', 'pre_sync_delay/1');
    add_line(blk, 'pre_sync_delay/1', 'sync_delay_en/1');
    add_line(blk, 'sync_delay_en/1', 'post_sync_delay/1');
    add_line(blk, 'en/1', 'sync_delay_en/2');
    add_line(blk, 'post_sync_delay/1', 'sync_out/1');
    add_line(blk, 'en/1', 'delay_we/1');
    add_line(blk, 'delay_we/1', 'delay_valid/1');
    add_line(blk, 'delay_valid/1', 'valid/1');

    % Add dynamic wires
    for i=1:n_inputs
        add_line(blk, 'delay_we/1', ['bram',tostring(i-1),'/3']);
        add_line(blk, 'Mux/1', ['bram',tostring(i-1),'/1']);
        add_line(blk, ['din',tostring(i-1),'/1'], ['delay_din',tostring(i-1),'/1']);
        add_line(blk, ['delay_din',tostring(i-1),'/1'], ['bram',tostring(i-1),'/2']);
        add_line(blk, ['bram',tostring(i-1),'/1'], ['dout',tostring(i-1),'/1']);
    end

    for i=1:order-1,
        mapname = ['map',tostring(i)];
        prevmapname = ['map',tostring(i-1)];
        if i == 1,
            add_line(blk, 'Slice2/1', 'map1/1');
        else,
            add_line(blk, [prevmapname,'/1'], [mapname,'/1'], 'autorouting', 'on');
        end
        add_line(blk, [mapname,'/1'], ['delay_',mapname,'/1']);
        add_line(blk, ['delay_',mapname,'/1'], ['Mux/',tostring(i+2)]);
    end
    
    
    
    
% case for order > 1, double-buffered
else,
    reuse_block(blk, 'Counter', 'xbsIndex_r4/Counter', ...
        'Position', [95    56   145   109],'n_bits', tostring(map_bits + 1), 'cnt_type', 'Count Limited', ...
        'arith_type', 'Unsigned', 'cnt_to', tostring(2^map_bits * 2 - 1), ...
        'en', 'on', 'rst', 'on');
    reuse_block(blk, 'Slice1', 'xbsIndex_r4/Slice', ...
        'Position', [170    37   200    53], 'mode', 'Upper Bit Location + Width', ...
        'nbits', '1');
    reuse_block(blk, 'Slice2', 'xbsIndex_r4/Slice', ...
        'Position', [170    77   200    93], 'mode', 'Lower Bit Location + Width', ...
        'nbits', tostring(map_bits));
    reuse_block(blk, 'delay_sel', 'xbsIndex_r4/Delay', ...
        'Position', [305    37    345    53], 'latency', tostring(map_latency));
    reuse_block(blk, 'delay_d0', 'xbsIndex_r4/Delay', ...
        'Position', [305    77    345    93], 'latency', tostring(map_latency));


    % Add Dynamic Ports and Blocks
    for i=1:n_inputs,
        % Ports
        reuse_block(blk, ['din',tostring(i-1)], 'built-in/inport', ...
            'Position', [495    80*i+3   525    80*i+17], 'Port', tostring(2+i));
        reuse_block(blk, ['dout', tostring(i-1)], 'built-in/outport', ...
            'Position', [705    80*i+3   735    80*i+17], 'Port', tostring(2+i));

        % BRAMS
        reuse_block(blk, ['delay_din',tostring(i-1)], 'xbsIndex_r4/Delay', ...
            'Position', [550    80*i    590    80*i+20], 'latency', tostring(map_latency));
        reuse_block(blk, ['dbl_buffer',tostring(i-1)], 'casper_library_reorder/dbl_buffer', ...
            'Position', [615    80*i-17   680   80*i+37], 'depth', tostring(2^map_bits), ...
            'latency', tostring(bram_latency));
    end

    % Add Maps
    mapname = 'map1';
    reuse_block(blk, mapname, 'xbsIndex_r4/ROM', ...
        'depth', tostring(map_length), 'initVector', tostring(map), 'latency', tostring(map_latency), ...
        'arith_type', 'Unsigned', 'n_bits', tostring(map_bits), 'bin_pt', '0', ...
        'distributed_mem', map_memory_type, 'Position', [230  125+50   270    145+50]);

    % Add static wires
    add_line(blk, 'sync/1', 'Counter/1');
    add_line(blk, 'en/1', 'Counter/2');
    add_line(blk, 'Counter/1', 'Slice1/1');
    add_line(blk, 'Counter/1', 'Slice2/1');
    add_line(blk, 'Slice1/1', 'delay_sel/1');
    add_line(blk, 'Slice2/1', 'delay_d0/1');
    add_line(blk, 'Slice2/1', 'map1/1');
    add_line(blk, 'sync/1', 'pre_sync_delay/1');
    add_line(blk, 'pre_sync_delay/1', 'sync_delay_en/1');
    add_line(blk, 'sync_delay_en/1', 'post_sync_delay/1');
    add_line(blk, 'en/1', 'sync_delay_en/2');
    add_line(blk, 'post_sync_delay/1', 'sync_out/1');
    add_line(blk, 'en/1', 'delay_we/1');
    add_line(blk, 'delay_we/1', 'delay_valid/1');
    add_line(blk, 'delay_valid/1', 'valid/1');

    % Add dynamic wires
    for i=1:n_inputs
        bram_name = ['dbl_buffer',tostring(i-1)];
        add_line(blk, 'delay_d0/1', [bram_name,'/2']);
        add_line(blk, 'map1/1', [bram_name,'/3']);
        add_line(blk, 'delay_we/1', [bram_name,'/5']);
        add_line(blk, 'delay_sel/1', [bram_name,'/1']);
        add_line(blk, ['din',tostring(i-1),'/1'], ['delay_din',tostring(i-1),'/1']);
        add_line(blk, ['delay_din',tostring(i-1),'/1'], [bram_name,'/4']);
        add_line(blk, [bram_name,'/1'], ['dout',tostring(i-1),'/1']);
    end
end

