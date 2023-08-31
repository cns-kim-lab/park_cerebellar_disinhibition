#include "handler/handler.h"
#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "datalayer/paths.hpp"
#include "volume/segmentation.h"
#include <memory>

using ::testing::_;
using namespace ::zi::mesh;

namespace om {
namespace test {

TEST(TaskSpawnTest, Case1) {
  file::Paths prePaths("/omniData/e2198/e2198_bc_s17_86_3_e24_101_16.omni");
  file::Paths postPaths("/omniData/e2198/e2198_bh_s18_86_16_e26_101_31.omni");
  volume::Segmentation pre(prePaths, 1);
  volume::Segmentation post(postPaths, 1);

  std::set<int> segs({1037975, 1039368, 1039480, 1061408, 1062016, 1083185,
                      1084004, 1085998, 1090552, 1092491, 1095443, 1096127,
                      1103096, 1103976, 1105366, 1105370, 1111813, 1118021,
                      1118624, 1125898});

  std::vector<std::map<int32_t, int32_t>> seedIds;
  handler::get_seeds(seedIds, pre, segs, post);
  EXPECT_GT(seedIds.size(), 0);
}

TEST(TaskSpawnTest, Case2) {
  file::Paths prePaths("/omniData/e2198/e2198_dl_s16_101_1_e24_116_16.omni");
  file::Paths postPaths("/omniData/e2198/e2198_bc_s17_86_3_e24_101_16.omni");
  volume::Segmentation pre(prePaths, 1);
  volume::Segmentation post(postPaths, 1);

  std::set<int> segs{
      1040709, 1040726, 1041361, 1041548, 1041738, 1041848, 1042484, 1042614,
      1042735, 1042863, 1043028, 1043419, 1043530, 1043729, 1044156, 1044200,
      1044743, 1044820, 1044854, 1045356, 1045667, 1045786, 1045854, 1061884,
      1066928, 1235317, 1235641, 1236381, 1257770, 1257958, 1258043, 1258080,
      1258114, 1258179, 1258215, 1258235, 1258263, 1258319, 1258419, 1258458,
      1264010, 1264012, 1264032, 1264060, 1264280, 1264422, 1286874, 1287078,
      1287518, 1287620, 1287622, 1288167, 1288306, 1288401, 1288569, 1288570,
      260732,  260845,  265399,  266320,  266986,  267438,  267558,  267559,
      267563,  267632,  267662,  267743,  267790,  267804,  267834,  267975,
      268003,  268097,  268132,  268283,  268326,  268436,  268562,  273793,
      273863,  273956,  273960,  274038,  274041,  274042,  274073,  274077,
      274096,  274135,  286030,  287876,  287931,  288616,  288720,  288853,
      289536,  289739,  289924,  289943,  289945,  289947,  290082,  290147,
      290148,  290186,  290358,  290361,  290441,  290585,  290674,  290764,
      290815,  290914,  290918,  290920,  290945,  290993,  290994,  291020,
      291028,  291039,  291077,  291100,  312749,  312767,  375373,  382233,
      400814,  403854,  404080,  405328,  405575,  405639,  405644,  405742,
      405900,  406061,  406211,  406249,  406956,  407074,  407115,  422919,
      423446,  423782,  425757,  425845,  425850,  425877,  425944,  425990,
      426064,  426067,  426157,  426187,  426190,  426204,  426205,  427348,
      427400,  427495,  427582,  427598,  427801,  427866,  429737,  429848,
      430024,  430038,  430100,  430237,  430259,  430580,  430610,  430611,
      430665,  430748,  430749,  430836,  430837,  430907,  430980,  431004,
      431037,  431039,  431056,  431071,  431076,  431089,  431114,  431120,
      431156,  431167,  431655,  434529,  434560,  434590,  434608,  434630,
      434702,  434706,  434714,  434753,  434774,  434780,  434790,  434805,
      434806,  434807,  434808,  434817,  434818,  434819,  434828,  434838,
      434839,  434840,  434841,  434842,  434843,  434848,  434863,  434873,
      434875,  434884,  434885,  434892,  434893,  434903,  434904,  434909,
      434911,  434918,  434919,  434920,  434927,  434934,  434935,  434938,
      434945,  434950,  434957,  434958,  434959,  434963,  434972,  434976,
      434982,  434989,  435000,  435005,  435021,  435024,  435059,  435095,
      435096,  435101,  435106,  447173,  447176,  447245,  447504,  447532,
      447535,  447646,  447874,  451360,  451384,  451426,  451442,  451651,
      451655,  451683,  451684,  451739,  451814,  451838,  452032,  452211,
      452401,  452403,  452501,  452537,  452540,  452541,  452575,  452697,
      452698,  452865,  452948,  453023,  453024,  454199,  455003,  455046,
      455133,  455188,  455225,  455388,  455402,  455405,  455596,  455649,
      455789,  455814,  455896,  455920,  456004,  456049,  456270,  456538,
      458027,  458028,  458096,  458124,  458125,  458127,  458132,  458133,
      458156,  458157,  458158,  458159,  458169,  458170,  458176,  458180,
      458183,  458193,  458215,  458218,  458222,  458229,  458234,  458238,
      458243,  458246,  458247,  458256,  458257,  458258,  458259,  458268,
      458269,  458282,  458283,  458288,  458295,  458296,  458307,  458327,
      458334,  458348,  458484,  469883,  469932,  470086,  470099,  470361,
      473369,  473668,  473769,  474020,  474348,  474366,  474390,  474422,
      474510,  474568,  474633,  474737,  474747,  474786,  490222,  490257,
      490321,  490561,  492833,  496191,  496264,  496380,  496409,  496450,
      496650,  496651,  496775,  496830,  496889,  497014,  516491,  516641,
      516995,  517392,  517502,  517522,  539138,  539292,  581324,  604183,
      628471,  628578,  628843,  630568,  630626,  631382,  631835,  633001,
      633173,  633274,  633429,  633468,  633500,  633579,  633660,  633662,
      633726,  633770,  633771,  633788,  634524,  634555,  634556,  634558,
      634608,  634931,  634982,  635140,  649346,  649411,  650397,  652047,
      652182,  652258,  652272,  652611,  656509,  673997,  674773,  675621,
      676477,  676992,  677063,  677767,  679052,  679162,  679219,  679220,
      696289,  696445,  696448,  696467,  696547,  696829,  696927,  697067,
      697234,  697365,  697427,  720490,  720782,  720892,  720913,  720924,
      720949,  720950,  720952,  721173,  721362,  721384,  742776,  833353,
      833368,  833468,  834580,  855268,  855311,  855314,  855348,  855431,
      855432,  855443,  855454,  855460,  858182,  858247,  858266,  859440};

  std::vector<std::map<int32_t, int32_t>> seedIds;
  handler::get_seeds(seedIds, pre, segs, post);

  ASSERT_EQ(1, seedIds.size());
  std::set<int32_t> expected{276782, 279057, 284363, 286329, 286869,
                             289497, 298489, 299114, 300193, 323571};
  // Check "expected" is the same as the keys in seedIds:
  // If the size of the union of two sets is different from the size of either
  // set, the two sets are different.
  EXPECT_EQ(expected.size(), seedIds[0].size());
  for (auto val : expected) {
    seedIds[0][val] = 1;
  }
  EXPECT_EQ(expected.size(), seedIds[0].size());
}

TEST(TaskSpawnTest, Case3) {
  file::Paths prePaths("/omniData/e2198/e2198_dl_s16_101_1_e24_116_16.omni");
  file::Paths postPaths("/omniData/e2198/e2198_dn_s16_116_1_e24_131_16.omni");
  volume::Segmentation pre(prePaths, 1);
  volume::Segmentation post(postPaths, 1);

  std::set<int> segs{
      1040709, 1040726, 1041361, 1041548, 1041738, 1041848, 1042484, 1042614,
      1042735, 1042863, 1043028, 1043419, 1043530, 1043729, 1044156, 1044200,
      1044743, 1044820, 1044854, 1045356, 1045667, 1045786, 1045854, 1061884,
      1066928, 1235317, 1235641, 1236381, 1257770, 1257958, 1258043, 1258080,
      1258114, 1258179, 1258215, 1258235, 1258263, 1258319, 1258419, 1258458,
      1264010, 1264012, 1264032, 1264060, 1264280, 1264422, 1286874, 1287078,
      1287518, 1287620, 1287622, 1288167, 1288306, 1288401, 1288569, 1288570,
      260732,  260845,  265399,  266320,  266986,  267438,  267558,  267559,
      267563,  267632,  267662,  267743,  267790,  267804,  267834,  267975,
      268003,  268097,  268132,  268283,  268326,  268436,  268562,  273793,
      273863,  273956,  273960,  274038,  274041,  274042,  274073,  274077,
      274096,  274135,  286030,  287876,  287931,  288616,  288720,  288853,
      289536,  289739,  289924,  289943,  289945,  289947,  290082,  290147,
      290148,  290186,  290358,  290361,  290441,  290585,  290674,  290764,
      290815,  290914,  290918,  290920,  290945,  290993,  290994,  291020,
      291028,  291039,  291077,  291100,  312749,  312767,  375373,  382233,
      400814,  403854,  404080,  405328,  405575,  405639,  405644,  405742,
      405900,  406061,  406211,  406249,  406956,  407074,  407115,  422919,
      423446,  423782,  425757,  425845,  425850,  425877,  425944,  425990,
      426064,  426067,  426157,  426187,  426190,  426204,  426205,  427348,
      427400,  427495,  427582,  427598,  427801,  427866,  429737,  429848,
      430024,  430038,  430100,  430237,  430259,  430580,  430610,  430611,
      430665,  430748,  430749,  430836,  430837,  430907,  430980,  431004,
      431037,  431039,  431056,  431071,  431076,  431089,  431114,  431120,
      431156,  431167,  431655,  434529,  434560,  434590,  434608,  434630,
      434702,  434706,  434714,  434753,  434774,  434780,  434790,  434805,
      434806,  434807,  434808,  434817,  434818,  434819,  434828,  434838,
      434839,  434840,  434841,  434842,  434843,  434848,  434863,  434873,
      434875,  434884,  434885,  434892,  434893,  434903,  434904,  434909,
      434911,  434918,  434919,  434920,  434927,  434934,  434935,  434938,
      434945,  434950,  434957,  434958,  434959,  434963,  434972,  434976,
      434982,  434989,  435000,  435005,  435021,  435024,  435059,  435095,
      435096,  435101,  435106,  447173,  447176,  447245,  447504,  447532,
      447535,  447646,  447874,  451360,  451384,  451426,  451442,  451651,
      451655,  451683,  451684,  451739,  451814,  451838,  452032,  452211,
      452401,  452403,  452501,  452537,  452540,  452541,  452575,  452697,
      452698,  452865,  452948,  453023,  453024,  454199,  455003,  455046,
      455133,  455188,  455225,  455388,  455402,  455405,  455596,  455649,
      455789,  455814,  455896,  455920,  456004,  456049,  456270,  456538,
      458027,  458028,  458096,  458124,  458125,  458127,  458132,  458133,
      458156,  458157,  458158,  458159,  458169,  458170,  458176,  458180,
      458183,  458193,  458215,  458218,  458222,  458229,  458234,  458238,
      458243,  458246,  458247,  458256,  458257,  458258,  458259,  458268,
      458269,  458282,  458283,  458288,  458295,  458296,  458307,  458327,
      458334,  458348,  458484,  469883,  469932,  470086,  470099,  470361,
      473369,  473668,  473769,  474020,  474348,  474366,  474390,  474422,
      474510,  474568,  474633,  474737,  474747,  474786,  490222,  490257,
      490321,  490561,  492833,  496191,  496264,  496380,  496409,  496450,
      496650,  496651,  496775,  496830,  496889,  497014,  516491,  516641,
      516995,  517392,  517502,  517522,  539138,  539292,  581324,  604183,
      628471,  628578,  628843,  630568,  630626,  631382,  631835,  633001,
      633173,  633274,  633429,  633468,  633500,  633579,  633660,  633662,
      633726,  633770,  633771,  633788,  634524,  634555,  634556,  634558,
      634608,  634931,  634982,  635140,  649346,  649411,  650397,  652047,
      652182,  652258,  652272,  652611,  656509,  673997,  674773,  675621,
      676477,  676992,  677063,  677767,  679052,  679162,  679219,  679220,
      696289,  696445,  696448,  696467,  696547,  696829,  696927,  697067,
      697234,  697365,  697427,  720490,  720782,  720892,  720913,  720924,
      720949,  720950,  720952,  721173,  721362,  721384,  742776,  833353,
      833368,  833468,  834580,  855268,  855311,  855314,  855348,  855431,
      855432,  855443,  855454,  855460,  858182,  858247,  858266,  859440};

  std::vector<std::map<int32_t, int32_t>> seedIds;
  handler::get_seeds(seedIds, pre, segs, post);

  std::vector<std::set<int32_t>> expected{{608763, 614337}, {263128}};
  ASSERT_EQ(expected.size(), seedIds.size());
  // Check "expected" is the same as the keys in seedIds:
  // If the size of the union of two sets is different from the size of either
  // set, the two sets are different.
  if (seedIds.size() == expected.size()) {
    for (auto i = 0; i < expected.size(); ++i) {
      EXPECT_EQ(expected[i].size(), seedIds[i].size());
      for (auto val : expected[i]) {
        seedIds[i][val] = 1;
      }
      EXPECT_EQ(expected[i].size(), seedIds[i].size());
    }
  }
}

TEST(TaskSpawnTest, Case4) {
  file::Paths prePaths(
      "/omniweb_data/x04/y61/x04y61z28_s1139_13939_6483_e1394_14194_6738.omni");
  file::Paths postPaths(
      "/omniweb_data/x04/y62/x04y62z28_s1139_14163_6483_e1394_14418_6738.omni");
  volume::Segmentation pre(prePaths, 1);
  volume::Segmentation post(postPaths, 1);

  std::set<int> segs{1739};

  std::vector<std::map<int32_t, int32_t>> seedIds;
  handler::get_seeds(seedIds, pre, segs, post);

  std::vector<std::set<int32_t>> expected{{1363, 2420}};
  ASSERT_EQ(expected.size(), seedIds.size());
  // Check "expected" is the same as the keys in seedIds:
  // If the size of the union of two sets is different from the size of either
  // set, the two sets are different.
  if (seedIds.size() == expected.size()) {
    for (auto i = 0; i < expected.size(); ++i) {
      EXPECT_EQ(expected[i].size(), seedIds[i].size());
      for (auto val : expected[i]) {
        seedIds[i][val] = 1;
      }
      EXPECT_EQ(expected[i].size(), seedIds[i].size());
    }
  }
}

TEST(TaskSpawnTest, Case5_EmptyIntersection) {
  file::Paths prePaths(
      "/omniweb_data/x09/y34/x09y34z07_s2259_7891_1779_e2514_8146_2034.omni");
  file::Paths postPaths(
      "/omniweb_data/x09/y35/x09y35z07_s2259_8115_1779_e2514_8370_2034.omni");
  volume::Segmentation pre(prePaths, 1);
  volume::Segmentation post(postPaths, 1);

  std::set<int> segs{3141, 4226, 4367, 4451, 4494,
                     4560, 4580, 4581, 4597, 4699};

  std::vector<std::map<int32_t, int32_t>> seedIds;
  handler::get_seeds(seedIds, pre, segs, post);

  ASSERT_EQ(0, seedIds.size());
}

TEST(TaskSpawnTest, Case6_DoesNotEscape) {
  file::Paths prePaths(
      "/omniweb_data/x07/y34/x07y34z41_s1811_7891_9395_e2066_8146_9650.omni");
  file::Paths postPaths(
      "/omniweb_data/x07/y34/x07y34z40_s1811_7891_9171_e2066_8146_9426.omni");
  volume::Segmentation pre(prePaths, 1);
  volume::Segmentation post(postPaths, 1);

  std::set<int> segs{734,944,971,1266,1433,1848, 2029};

  std::vector<std::map<int32_t, int32_t>> seedIds;
  handler::get_seeds(seedIds, pre, segs, post);

  ASSERT_EQ(0, seedIds.size());
}
}
}  // namespace om::test::
