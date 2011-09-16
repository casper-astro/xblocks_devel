function outputs = xblock_new_outputs( name, M, N )

outputs = {};
for m = 1:M
    for n = 1:N
        outputs{m,n} = xOutport( [name, '_', num2str(m), '_', num2str(n)] );
    end
end

end

