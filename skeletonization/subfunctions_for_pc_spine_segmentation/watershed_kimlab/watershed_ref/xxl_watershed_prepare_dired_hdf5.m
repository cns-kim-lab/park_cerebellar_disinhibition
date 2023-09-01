function [ meta ] = xxl_watershed_prepare_dired_hdf5( conn, filename, width )

[ ign s ] = get_hdf5_size( conn, '/main' );

xind = 0;

f = fopen( [ filename '.chunksizes' ], 'w+' );
faff = fopen( [ filename '.affinity.data' ], 'w+' );

dirname = [ filename '.chunks' ];
[ ss sm si ] = mkdir( dirname );

for x = 1:width:s( 1 ),    
    [ ss sm si ] = mkdir( sprintf( '%s/%d', dirname, xind ));
    yind = 0;
    for y = 1:width:s( 2 ),
        [ ss sm si ] = mkdir( sprintf( '%s/%d/%d', dirname, xind, yind ));
        zind = 0;
        for z = 1:width:s( 3 ),
            [ ss sm si ] = mkdir( sprintf( '%s/%d/%d/%d', dirname, xind, yind, zind ));
            
            cto   = min( [ x y z ] + width, s( 1:3 ) );
            cfrom = max( [ 1 1 1 ], [ x y z ] - 1 );
            fwrite( f, cto - cfrom + 1, 'int32' );
            
            %fname = sprintf( '%s/%d/%d/%d/affinity.data', dirname, xind, yind, zind );
            %fd = fopen( fname, 'w+' );
            
            part = get_hdf5_file( conn, '/main', [ cfrom 1 ], [ cto 3 ] );
            fwrite( faff, single( part ), 'float' );
            %fwrite( fd, conn( cfrom(1):cto(1), cfrom(2):cto(2), cfrom(3):cto(3), : ), 'float' );
            %fclose( fd );
            
            fprintf( 'prepared chunk %d:%d:%d size: [ %d %d %d ]\n', ...
                     x, y, z, cto - cfrom + 1 );
            
            zind = zind + 1;
        end;
        yind = yind + 1;
    end;
    xind = xind + 1;
end

meta = [ 32 32 xind yind zind ];

fd = fopen( [ filename '.metadata' ], 'w+' );
fwrite( fd, meta, 'int32' );
fclose( fd );

fclose( f );
fclose( faff );