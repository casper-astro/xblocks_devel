function bit_reverser_init_xblock(blk, varargin)

defaults = { ...
    'n_bits', 1, ...
    };

n_bits = get_var('n_bits', 'defaults', defaults, varargin{:});

din = xInport('din');
dout = xOutport('dout');

slice_outs = {};

for k=1:n_bits
    slice_out = xSignal;
    xBlock( struct('source', 'Slice', 'name', ['slice_', num2str(k)]), ...
        struct('mode', 'Lower Bit Location + Width', 'bit0', k-1, 'base0', 'LSB of Input'), ...
        {din}, {slice_out});
    slice_outs{k} = slice_out;
end

if(n_bits==1)
    dout.bind(din);
else
    xBlock(struct('source', 'Concat', 'name', 'rev_concat'), ...
    struct('num_inputs', n_bits), slice_outs, {dout});
end


end