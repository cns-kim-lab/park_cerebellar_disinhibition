function [ dend dend_vals ] = xxl_watershed_read_global( filename, s, width )

global seg;

seg = zeros( s(1:3), 'uint32' );

xind = 0;
for x = 1:width:s( 1 ),
    yind = 0;
    for y = 1:width:s( 2 ),
        zind = 0;
        for z = 1:width:s( 3 ),

            cto   = min( [ x y z ] + width, s( 1:3 ) );
            cfrom = max( [ 1 1 1 ], [ x y z ] - 1 );

            fname = sprintf( '%s.chunks/%d/%d/%d/.seg', filename, xind, yind, zind );
            fd = fopen( fname, 'r' );

            sze = cto - cfrom + 1;

            chk = reshape( fread( fd, prod( sze ), 'int32' ), sze );

            seg( cfrom(1)+1:cto(1)-1, cfrom(2)+1:cto(2)-1, cfrom(3)+1:cto(3)-1 ) = chk( 2:end-1, 2:end-1, 2:end-1);

            fprintf( 'prepared chunk %d:%d:%d fname: %s, size: [ %d %d %d ]\n', ...
                     x, y, z, fname, cto - cfrom + 1 );
            fclose( fd );

            zind = zind + 1;
        end;
        yind = yind + 1;
    end;
    xind = xind + 1;
end

fd = fopen( [ filename '.dend_values' ], 'r' );
dend_vals = single(fread( fd, 1000000000, 'float' ));
fclose( fd );

fd = fopen( [ filename '.dend_pairs' ], 'r' );
dend = zeros( 2, size( dend_vals, 1 ) );
dend(:) = fread( fd, size( dend_vals )*2, 'uint32' );
dend = uint32(dend');
fclose( fd );
