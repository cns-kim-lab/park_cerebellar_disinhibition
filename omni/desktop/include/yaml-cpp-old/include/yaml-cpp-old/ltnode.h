#ifndef LTNODE_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
#define LTNODE_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD

#if !defined(__GNUC__) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || (__GNUC__ >= 4) // GCC supports "pragma once" correctly since 3.4
#pragma once
#endif


namespace YAMLold
{
	class Node;

	struct ltnode {
		bool operator()(const Node *pNode1, const Node *pNode2) const;
	};
}

#endif // LTNODE_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
