#ifndef ANCHOR_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
#define ANCHOR_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD

#if !defined(__GNUC__) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || (__GNUC__ >= 4) // GCC supports "pragma once" correctly since 3.4
#pragma once
#endif

#include <cstddef>

namespace YAMLold
{
	typedef std::size_t anchor_t;
	const anchor_t NullAnchor = 0;
}

#endif // ANCHOR_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
