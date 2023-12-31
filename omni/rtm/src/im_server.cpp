
// This autogenerated skeleton file illustrates how to build a server.
// You should copy it to another filename to avoid overwriting it.

#include "detail/log.hpp"
#include "RealTimeMesher.h"
#include <protocol/TBinaryProtocol.h>
#include <server/TSimpleServer.h>
#include <transport/TServerSocket.h>
#include <transport/TBufferTransports.h>
#include <protocol/TBinaryProtocol.h>
#include <server/TSimpleServer.h>
#include <server/TThreadPoolServer.h>
#include <server/TNonblockingServer.h>
#include <transport/TServerSocket.h>
#include <transport/TBufferTransports.h>
#include <concurrency/ThreadManager.h>
#include <concurrency/PosixThreadFactory.h>
#include "interactive_mesh.hpp"

#include <zi/arguments.hpp>
#include <zi/time.hpp>
#include <zi/concurrency.hpp>
#include <zi/system/daemon.hpp>

ZiARG_int32(port, 9099, "Server's port");
ZiARG_bool(daemonize, true, "Run as daemon");


using namespace ::apache::thrift;
using namespace ::apache::thrift::protocol;
using namespace ::apache::thrift::transport;
using namespace ::apache::thrift::concurrency;
using namespace ::apache::thrift::server;

using boost::shared_ptr;

using namespace  ::zi::mesh;

class RealTimeMesherHandler : virtual public RealTimeMesherIf {
private:
    zi::mutex                                          mutex_ ;
    std::map< uint32_t, shared_ptr<interactive_mesh> > meshes_;
    zi::rwmutex                                        incall_;

private:
    shared_ptr<interactive_mesh> get_mesher(uint32_t id)
    {
        zi::mutex::guard g(mutex_);
        if ( meshes_.count(id) == 0 )
        {
            meshes_[id] = shared_ptr<interactive_mesh>(new interactive_mesh(id));
        }

        return meshes_[id];
    }

    shared_ptr<interactive_mesh> get_mesher(const std::string& uri )
    {
        uint32_t id = boost::lexical_cast<uint32_t>(uri);

        zi::mutex::guard g(mutex_);
        if ( meshes_.count(id) == 0 )
        {
            meshes_[id] = shared_ptr<interactive_mesh>(new interactive_mesh(id));
        }

        return meshes_[id];
    }

public:
    RealTimeMesherHandler()
        : mutex_()
        , meshes_()
    {
        zi::rwmutex::write_guard g(incall_);

        std::list<std::string> l;
        file::ls(l, "./data");

        LOG(out) << "Found " << l.size() << " cells\n";

        FOR_EACH( it, l )
        {
            get_mesher(*it);
        }
    }

    ~RealTimeMesherHandler()
    {
        LOG(out) << "RealTimeMesherHandler ZAP\n";
    }

    bool updateChunk(const std::string& uri, const Vector3i& chunk, const std::string& data) {
        zi::rwmutex::read_guard g(incall_);
        // Your implementation goes here
        //sleep(1);
        printf("updateChunk\n");
        return true;
    }

    bool update( const std::string& uri,
                 const Vector3i& location,
                 const Vector3i& size,
                 const std::string& data)
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        uint32_t id = boost::lexical_cast<uint32_t>(uri);

        shared_ptr<interactive_mesh> m = get_mesher(id);
        m->volume_update_inner( location.x, location.y, location.z,
                                size.x, size.y, size.z,
                                2, data.data());

        LOG(request) << "update(" << uri << ", "
                     << location.x << ", " << location.y << ", " << location.z
                     << ") [" << t.elapsed<double>() << "]";

        return true;
    }

    bool maskedUpdate( const std::string& uri,
                       const Vector3i& location,
                       const Vector3i& size,
                       const std::string& data,
                       const std::string& mask)
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        uint32_t id = boost::lexical_cast<uint32_t>(uri);

        shared_ptr<interactive_mesh> m = get_mesher(id);
        m->volume_update_inner( location.x, location.y, location.z,
                                size.x, size.y, size.z,
                                0, data.data(), mask.data() );

        LOG(request) << "maskedUpdate(" << uri << ", "
                     << location.x << ", " << location.y << ", " << location.z
                     << ") [" << t.elapsed<double>() << "]";

        return true;
    }

    bool customMaskedUpdate( const std::string& uri,
                             const Vector3i& location,
                             const Vector3i& size,
                             const std::string& data,
                             const std::string& mask,
                             const int64_t options )
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        uint32_t id = boost::lexical_cast<uint32_t>(uri);

        shared_ptr<interactive_mesh> m = get_mesher(id);
        m->volume_update_inner( location.x, location.y, location.z,
                                size.x, size.y, size.z,
                                0, data.data(), mask.data(),
                                options & 1);

        LOG(request) << "maskedUpdate(" << uri << ", "
                     << location.x << ", " << location.y << ", " << location.z
                     << ") [" << t.elapsed<double>() << "]";

        return true;
    }

    void getMesh( MeshDataResult& _return,
                  const std::string& uri,
                  const MeshCoordinate& c)
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        uint32_t id = boost::lexical_cast<uint32_t>(uri);
        shared_ptr<interactive_mesh> m = get_mesher(id);

        _return.mesh.hash = static_cast<int64_t>(
            m->get_mesh( zi::mesh::vec4u(c.x, c.y, c.z, c.mip),
                         _return.mesh.data ) );

        LOG(request) << "getMesh(" << uri << ", "
                     << c.x << ", " << c.y << ", " << c.z << ", " << c.mip
                     << ") [" << (_return.mesh.data.size() / 1024) << "KB"
                     << "] [" << t.elapsed<double>() << "]";
    }

    void getMeshes( std::vector<MeshDataResult> & _return,
                    const std::string& uri,
                    const std::vector<MeshCoordinate> & cs)
    {
        zi::rwmutex::read_guard g(incall_);
        _return.resize(cs.size());

        for ( std::size_t i = 0; i < cs.size(); ++i )
        {
            getMesh(_return[i], uri, cs[i]);
        }
    }

    void getMeshIfNewer( MeshDataResult& _return,
                         const std::string& uri,
                         const MeshCoordinate& c,
                         const int64_t version)
    {
        zi::rwmutex::read_guard g(incall_);
        shared_ptr<interactive_mesh> m = get_mesher(uri);

        if ( static_cast<int64_t>(m->get_hash(c.x,c.y,c.z,c.mip)) != version )
        {

            _return.mesh.hash = static_cast<int64_t>(
                m->get_mesh( zi::mesh::vec4u(c.x, c.y, c.z, c.mip),
                             _return.mesh.data ) );

            printf("getMesh: %s: %d, %d, %d Mip: %d Id: %d (%ld)\n",
                   uri.c_str(), c.x, c.y, c.z, c.mip, c.segID,
                   _return.mesh.data.size());
        }
        else
        {
            _return.mesh.hash = 0;
            _return.mesh.data = "";
        }
    }

    void getMeshesIfNewer( std::vector<MeshDataResult> & _return,
                           const std::string& uri,
                           const std::vector<MeshCoordinate> & cs,
                           const std::vector<int64_t> & versions)
    {
        zi::rwmutex::read_guard g(incall_);
        _return.resize(cs.size());

        for ( std::size_t i = 0; i < cs.size(); ++i )
        {
            getMeshIfNewer(_return[i], uri, cs[i], versions[i]);
        }
    }

    int64_t getMeshVersion( const std::string& uri,
                            const MeshCoordinate& c)
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        return get_mesher(uri)->get_hash(c.x, c.y, c.z, c.mip);

        LOG(request) << "getMeshVersion(" << uri
                     << ") [" << t.elapsed<double>() << "]";
    }

    void getMeshVersions( std::vector<int64_t> & _return,
                          const std::string& uri,
                          const std::vector<MeshCoordinate> & c)
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        std::vector< zi::mesh::vec4u > vc( c.size() );
        for ( std::size_t i = 0; i < c.size(); ++i )
        {
            vc[i] = vec4u(c[i].x,c[i].y,c[i].z,c[i].mip);
        }

        get_mesher(uri)->get_hashes(_return, vc);

        LOG(request) << "getMeshVersions(" << uri << ", " << c.size()
                     << ") [" << t.elapsed<double>() << "]";
    }

    void clear( const std::string& uri )
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        get_mesher(uri)->clear();

        LOG(request) << "clear(" << uri << ") [" << t.elapsed<double>() << "]";
    }

    void remesh( const std::string& uri )
    {
        zi::wall_timer t;

        zi::rwmutex::read_guard g(incall_);
        get_mesher(uri)->remesh();

        LOG(request) << "remesh(" << uri << ") [" << t.elapsed<double>() << "]";
    }


    void die()
    {
        zi::rwmutex::write_guard g(incall_);
        {
            zi::mutex::guard g(mutex_);
            meshes_.clear();
        }
    }

};


static bool should_die = false;

static void die_loop(shared_ptr<TNonblockingServer> s,
                     shared_ptr<RealTimeMesherHandler> h)
{
    while (1)
    {
        if ( should_die )
        {
            s->stop();
            LOG(out) << "Server stopped\n";
            h->die();
            LOG(out) << "Handler killed\n";
            return;
        }
        usleep(1000000);
    }
}

void signal_handler( int param )
{
    LOG(out) << "SIGNAL: " << param << " caught\n";
    should_die = true;
}

int main(int argc, char **argv)
{

    zi::parse_arguments(argc, argv, true);
    if ( ZiARG_daemonize )
    {
        if( !::zi::system::daemonize(true, true) )
        {
            std::cerr << "Error trying to daemonize." << std::endl;
            return -1;
        }
    }

    // logging thread should only be started after daemonize()
    log_output.start();

    // Needed by chunk_io, fmesh_io and smesh_io to serve data
    file_io.create_dir("./data/");

    int port = ZiARG_port;

    shared_ptr<RealTimeMesherHandler> handler(new RealTimeMesherHandler());
    shared_ptr<TProcessor> processor(new RealTimeMesherProcessor(handler));
    shared_ptr<TServerTransport> serverTransport(new TServerSocket(port));
    shared_ptr<TTransportFactory> transportFactory(new TBufferedTransportFactory());
    shared_ptr<TProtocolFactory> protocolFactory(new TBinaryProtocolFactory());

    boost::shared_ptr<ThreadManager> threadManager
        (ThreadManager::newSimpleThreadManager(32));
    boost::shared_ptr<PosixThreadFactory> threadFactory(new PosixThreadFactory());

    threadManager->threadFactory(threadFactory);
    threadManager->start();

    boost::shared_ptr<TNonblockingServer> server(
        new TNonblockingServer(processor, transportFactory, transportFactory,
                               protocolFactory, protocolFactory, port, threadManager));


    zi::thread t(zi::run_fn(zi::bind(&die_loop, server, handler)));

    signal(SIGTERM, signal_handler);
    signal(SIGABRT, signal_handler);
    signal(SIGINT , signal_handler);

    t.start();

    // {
    //     Vector3i l;
    //     l.x = 14*128-250;
    //     l.y = 25*128-250;
    //     l.z = 36*128-250;

    //     Vector3i s; s.x=s.y=s.z=1024;

    //     std::size_t slen = 2*2*2*512*512*512;
    //     char* st = new char[slen*4];
    //     memset(st,0,slen*4);

    //     char* st2 = new char[slen];
    //     memset(st2,1,slen);

    //     handler->maskedUpdate( "61",
    //                   l, s, std::string(st,slen*4),
    //                   std::string(st2,slen));

    // }

    // handler->remesh("81");

    server->serve();

    t.join();

    return 0;
}

