// Copyright (c) 2010-2024 The Open-Transactions developers
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Patched for WASM/Emscripten: ZMQ inproc socket connect can fail in worker
// threads. Rather than calling std::terminate(), fall back to Console backend.

#include "opentxs/util/log/backend/ZeroMQ.internal.hpp"  // IWYU pragma: associated

#include "opentxs/api/session/Endpoints.internal.hpp"
#include "opentxs/external/boost/scope.hpp"
#include "opentxs/external/stl.hpp"
#include "opentxs/network/zeromq/Context.internal.hpp"
#include "opentxs/network/zeromq/Socket.hpp"
#include "opentxs/network/zeromq/Socket.internal.hpp"
#include "opentxs/network/zeromq/message/Message.hpp"
#include "opentxs/network/zeromq/socket/Type.hpp"  // IWYU pragma: keep
#include "opentxs/network/zeromq/socket/Types.hpp"
#include "opentxs/util/WorkType.internal.hpp"
#include "opentxs/util/alloc/Strategy.hpp"
#include "opentxs/util/log/backend/Console.internal.hpp"

namespace opentxs::inline util::log::backend
{
ZeroMQ::ZeroMQ() noexcept
    : data_(std::make_shared<GuardedData>())
{
    if (nullptr == data_) {
        std::abort();
    }
}

auto ZeroMQ::Get() noexcept -> ZeroMQ&
{
    static auto instance = ZeroMQ{};

    return instance;
}

auto ZeroMQ::make_logger(ZMQ zmq) noexcept -> std::shared_ptr<Backend>
{
    using enum network::zeromq::socket::Type;

    if (nullptr == zmq) {
        std::abort();
    }

    struct Logger final : public Backend {
        std::weak_ptr<network::zeromq::internal::Context const> zmq_;
        network::zeromq::Socket socket_;

        auto Print(
            std::thread::id thread,
            std::string_view message,
            int level,
            bool isError,
            bool isFatal) noexcept -> void final
        {
            auto const threadID = [&] {
                auto out = std::stringstream{};
                out << thread;

                return out.str();
            }();

            if (auto zmq = zmq_.lock(); nullptr != zmq) {
                std::ignore = socket_.Internal().SendDeferred([&]() {
                    auto out = MakeWork(ot_zmq_log_message_);
                    out.AddFrame(level);
                    out.AddFrame(message.data(), message.size());
                    out.AddFrame(threadID.data(), threadID.size());
                    out.AddFrame(isError);
                    out.AddFrame(isFatal);

                    return out;
                }());
            } else {
                Console().Get().Print(thread, message, level, isError, isFatal);
            }
        }

        Logger(ZMQ zmq, network::zeromq::Socket socket) noexcept
            : zmq_(zmq)
            , socket_(std::move(socket))
        {
        }
    };

    auto socket = zmq->MakeSocket(Push, alloc::Strategy{});  // TODO allocator

    if (false == socket.Internal().SetOutgoingHWM(0)) {
        return std::make_shared<Console>();
    }

    using api::session::internal::Endpoints;

    if (false == socket.ConnectNullTerminated(Endpoints::LogBackend().data())) {
        return std::make_shared<Console>();
    }

    return std::make_shared<Logger>(zmq, std::move(socket));
}

auto ZeroMQ::Print(
    std::thread::id const thread,
    std::string_view const message,
    int const level,
    bool const isError,
    bool const isFatal) noexcept -> void
{
    Console::Get().Print(thread, message, level, isError, isFatal);
}

auto ZeroMQ::Register(ZMQ zmq) noexcept -> void
{
    auto handle = data_->lock();
    auto& data = *handle;
    data.zmq_ = zmq;
    data.map_.clear();
}

auto ZeroMQ::Thread() noexcept -> std::shared_ptr<Backend>
{
    auto const id = std::this_thread::get_id();
    static thread_local auto cleanup = boost::scope::make_scope_exit(
        [id, data = data_] { data->lock()->map_.erase(id); });
    auto handle = data_->lock();
    auto& data = *handle;
    auto zmq = data.zmq_.lock();
    auto& map = data.map_;

    if (zmq) {
        if (auto i = map.find(id); map.end() != i) {

            return i->second;
        } else {
            std::tie(i, std::ignore) = map.try_emplace(id, make_logger(zmq));

            if (nullptr == i->second) {
                std::abort();
            }

            return i->second;
        }
    } else {
        map.clear();

        return std::make_shared<Console>();
    }
}

ZeroMQ::~ZeroMQ() = default;
}  // namespace opentxs::inline util::log::backend
