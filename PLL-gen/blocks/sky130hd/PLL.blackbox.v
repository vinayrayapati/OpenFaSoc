(* blackbox *) module VCO(
  output OUT,
  input IN
);
endmodule
(* keep_hierarchy *)
(* blackbox *) module CP(
  input UP,
  input DN,
  output OUT
);
parameter dont_touch = "on";
endmodule
