// Copyright (c) 2010-2024 The Open-Transactions developers
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "opentxs/util/storage/driver/Filesystem.internal.hpp"  // IWYU pragma: associated

#include "opentxs/external/platform/posix.hpp"

namespace opentxs::inline util::storage::driver
{
auto Filesystem::sync(DescriptorType::handle_type fd) noexcept -> bool
{
    return 0 == ::fsync(fd);
}
}  // namespace opentxs::inline util::storage::driver
