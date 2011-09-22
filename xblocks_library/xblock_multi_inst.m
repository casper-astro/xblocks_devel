function outputs = xblock_multi_inst( config, params, inputs, n_outputs )

n_blocks, n_inputs = size(inputs);
outputs = xblock_new_bus(n_blocks, n_outputs);
for k=1:n_blocks
    xBlock(config, params, {inputs{k,:}}, {outputs{k,:}});
end

end

