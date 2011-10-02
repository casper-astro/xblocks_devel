function rcmult_init_xblock(blk, varargin)


defaults = {'latency', 4};
latency = get_var('latency','defaults', defaults, varargin{:});

%% inports
xlsub2_d = xInport('d');
xlsub2_sin = xInport('sin');
xlsub2_cos = xInport('cos');

%% outports
xlsub2_real = xOutport('real');
xlsub2_imag = xOutport('imag');

%% diagram

% block: rcmult_xblock_model/rcmult/Mult
xlsub2_Mult = xBlock(struct('source', 'Mult', 'name', 'Mult'), ...
                     struct('Precision', 'Full', ...
                            'latency', latency, ...
                            'use_rpm', 'off', ...
                            'placement_style', 'Rectangular shape'), ...
                     {xlsub2_d, xlsub2_cos}, ...
                     {xlsub2_real});

% block: rcmult_xblock_model/rcmult/Mult1
xlsub2_Mult1 = xBlock(struct('source', 'Mult', 'name', 'Mult1'), ...
                      struct('Precision', 'Full', ...
                             'latency', latency, ...
                             'use_rpm', 'off', ...
                             'placement_style', 'Rectangular shape'), ...
                      {xlsub2_d, xlsub2_sin}, ...
                      {xlsub2_imag});

% Set attribute format string (block annotation)
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    annotation=sprintf('');
    set_param(blk,'AttributesFormatString',annotation);
end

end

