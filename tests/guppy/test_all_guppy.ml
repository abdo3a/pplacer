open OUnit

let suite = [
  "kr_distance" >::: Test_kr_distance.suite;
  "pca" >::: Test_pca.suite;
  "power_iteration" >::: Test_power_iteration.suite;
]
