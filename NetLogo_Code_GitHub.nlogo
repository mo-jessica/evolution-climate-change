; file paths in this code are generic and must be customized for each computer

; variables accessible by all agents
globals
[
  farthest-patch
  centerx-hesperia
  centery-hesperia
  starting-patch-hesperia
  start-phenotype
  population-size
  branch-length
  stopping-point
  hesperia-extinctions

  species-list
  center-xcor
  center-ycor
  center
  farthest-turtle

  number-of-dispersals
  existing-species
  existing-species-v
]

; turtle variables
turtles-own
[
  species
  trait
  my-continent
]

; patch variables
patches-own
[
  continent
  province
  temperature
  precipitation
  precipitation-function
  elevation
  grit ; the amount of aerosols descending on the patch (min = 0, max = 1)
  biome ; the vegetative biome (derived from precipitation and temperature)
        ; forest, grassland, desert, or tundra
  biome-function
  hypsodonty-selection-factor  ; also the local selective optimum
                               ; the optimum phenotypic value of the patch based on local precipitation, grit, and biome
  average-trait-value
  ecometric-load
  species-richness
  individual-species-traits
]

; before the model begins, reset the model world and define initial variables. To set a random patch for the first turtle, uncomment the two lines starting with "set starting-patch...one-of patches..."
to setup
  clear-all
  reset-ticks
  input-geography
  set starting-patch-hesperia patch 17 57
  ; set starting-patch-hesperia one-of patches with [ continent = 1 ] ; can also use this in order to randomize starting position
  set stopping-point 400
  set branch-length 100
  set population-size 100
  calculate-selective-hypsodonty-selection-factor
  make-turtles
  initially-calculate-average-trait-value-for-patches
end

; calculate or recalculate local optimum of each patch based on precipitation, biome, and grit
to calculate-selective-hypsodonty-selection-factor
  ask patches with [ pcolor != 107 ]
  [
    ifelse precipitation > 100 [ set precipitation-function 0 ] [ set precipitation-function (( 100 - precipitation ) / 100) ]

    if biome = "Forest" [ set biome-function 0 ]
    if biome = "Tundra" [ set biome-function 0 ]
    if biome = "Desert" [ set biome-function 0.5 ]
    if biome = "Grassland" [ set biome-function 1 ]

    set hypsodonty-selection-factor ( grit + precipitation-function + biome-function )
  ]
end

; create the initial turtles in the model world and move them to the "starting patch" assigned in setup
to make-turtles
  if which-continent = "Hesperia" [
  create-turtles 1
  [
    move-to starting-patch-hesperia
    set trait ([ hypsodonty-selection-factor ] of patch-here)
    set species 1
    set color 5
    set my-continent [ continent ] of patch-here
  ]
    if hide-turtles [ ask turtles [ hide-turtle ] ] ]
end

; main model algorithm
to go
  if ticks = 0 [ first-speciation ]
  climate-change
  if ticks = 100 or ticks = 200 or ticks = 300 [ count-species other-speciations ]

  ask turtles [ disperse ]
  select-and-genetic-drift
  extirpate
  keep-one-turtle-of-each-species ; gene flow
  calculate-average-trait-value-for-patches
  calculate-ecometric-load
  calculate-species-richness
  calculate-individual-species-traits

  set existing-species 0
  set existing-species-v 0
  count-number-of-existing-species

  color-patches
  tick
  if export-view? [ export-view ( word "file/path/here" ticks ".png" ) ]

  if count turtles = 0
  [ stop ]

  if ticks = stopping-point
  [
    stop
  ]
end

; change precipitation by a set amount at a predetermined time
to climate-change
  ;  add precipitation at an interval
;    if climate-change? [ if ticks != 0 and ticks != 400 and ( remainder ticks 10 ) = 0
;    [ ask patches with [ pcolor != 107 ]
;      [ set precipitation ( precipitation + ( 200 / 39 ) ) ] ] ]

;  subtract precipitation at an interval
   if climate-change? [ if ticks != 0 and ticks != 400 and ( remainder ticks 10 ) = 0
      [ ask patches with [ pcolor != 107 ]
      [
        ifelse (precipitation - (200 / 39 )) >= 0
        [ set precipitation ( precipitation - ( 200 / 39 ) ) ]
        [ set precipitation 0 ] ] ] ]

; add precipitation at a specific time
;  if climate-change? [ if ticks = 200
;    [ ask patches with [ pcolor != 107 ]
;      [ set precipitation (precipitation + 100) ] ] ]

; subtract precipitation at a specific time
;  if climate-change? [ if ticks = 130 or ticks = 260
;      [ ask patches with [ pcolor != 107 ]
;      [
;      ifelse (precipitation - 100 ) >= 0
;      [ set precipitation (precipitation - 100) ]
;        [ set precipitation 0 ] ] ] ]

  ; recalculating biomes
  if climate-change? [ if ticks != 0 and ticks != 400 and ( remainder ticks 10 ) = 0
    [ calculate-biomes
      color-patches
   ] ]

  ask patches with [ pcolor != 107 ] [ calculate-selective-hypsodonty-selection-factor ]
end

; assign the biome of each patch based on temperature and precipitation values of the patch
to calculate-biomes
  ask patches with [ pcolor != 107 ] [ set biome "TBD" ]
  ask patches with [ biome = "TBD" ]
  [
    if temperature <= -5 [ set biome "Tundra" ]
    if temperature > -5 and precipitation <= 20 [ set biome "Desert" ]
    if temperature >= 5 and precipitation > 20 and precipitation <= 90 [ set biome "Grassland" ]
    if biome = "TBD" [ set biome "Forest" ]
  ]

end

; performs a selection event on a phenotype; the event is based on hypsodonty selection factor/local trait optimum, adaptive peak width, heritability, and phenotypic variance
; adaptive peak width determines how wide the selection surface is
; also performs random genetic drift
; applied to all turtles in the simulation.
to select-and-genetic-drift
  ask turtles
  [
    set trait (trait + ( ( ( hypsodonty-selection-factor - trait ) / ( adaptive-peak-width ^ 2 )) * heritability * phenotypic-variance )
    + random-normal 0 ((heritability * phenotypic-variance) / population-size) )
  ]
end

; each turtle has a probability of making a copy of itself in an adjacent patch
to disperse
  ; patch to the upper left
  if patch (xcor - 1) (ycor + 1) != nobody
  [ if [ pcolor ] of patch (xcor - 1) (ycor + 1) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor - 1) (ycor + 1)
        set number-of-dispersals (number-of-dispersals + 1) ] ] ]

  ; patch above
  if patch (xcor) (ycor + 1) != nobody
  [ if [ pcolor ] of patch (xcor) (ycor + 1) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor) (ycor + 1)
        set number-of-dispersals (number-of-dispersals + 1)] ] ]

  ; patch to the upper right
  if patch (xcor + 1) (ycor + 1) != nobody
  [ if [ pcolor ] of patch (xcor + 1) (ycor + 1) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor + 1) (ycor + 1)
        set number-of-dispersals (number-of-dispersals + 1) ] ] ]

  ; patch to the right
  if patch (xcor + 1) (ycor) != nobody
  [ if [ pcolor ] of patch (xcor + 1) (ycor) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor + 1) (ycor)
        set number-of-dispersals (number-of-dispersals + 1) ] ] ]

  ; patch to the lower right
  if patch (xcor + 1) (ycor - 1) != nobody
  [ if [ pcolor ] of patch (xcor + 1) (ycor - 1) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor + 1) (ycor - 1)
        set number-of-dispersals (number-of-dispersals + 1) ] ] ]

  ; patch below
  if patch (xcor) (ycor - 1) != nobody
  [ if [ pcolor ] of patch (xcor) (ycor - 1) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor) (ycor - 1)
        set number-of-dispersals (number-of-dispersals + 1) ] ] ]

  ; patch to the lower left
  if patch (xcor - 1) (ycor - 1) != nobody
  [ if [ pcolor ] of patch (xcor - 1) (ycor - 1) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor - 1) (ycor - 1)
        set number-of-dispersals (number-of-dispersals + 1) ] ] ]

  ; patch to the left
  if patch (xcor - 1) (ycor) != nobody
  [ if [ pcolor ] of patch (xcor - 1) (ycor) != 107 and random-float 1 <= dispersal-probability
    [ hatch 1
      [ move-to patch (xcor - 1) (ycor)
        set number-of-dispersals (number-of-dispersals + 1) ] ] ]
end

to calculate-average-trait-value-for-patches
  ask patches
  [
   ifelse (count turtles-here ) = 0
    [ set average-trait-value 99 ]
    [ set average-trait-value ( mean [ trait ] of turtles-here ) ]
  ]
end

to calculate-ecometric-load
  ask patches with [ count turtles-here != 0 ]
  [ set ecometric-load (average-trait-value - hypsodonty-selection-factor) ]
end

to calculate-species-richness
  ask patches with [ count turtles-here != 0 ]
  [ set species-richness (count turtles-here) ]
end

to keep-one-turtle-of-each-species
  ask turtles with [count turtles-here with [ species = [ species ] of myself ] >= 2]
  [
    set trait (mean [ trait ] of turtles-here with [ species = [ species ] of myself ] )
    ask other turtles-here with [ species = [ species ] of myself ]
    [ die ]
  ]
end

to initially-calculate-average-trait-value-for-patches
   ask patches [ set average-trait-value ( [ trait ] of turtles-here)]
end

; measures the distance between the optimal phenotype and the actual phenotype in terms of the adaptive peak width
; probability of extirpation increases with increasing distance
; probability of extirpation is also affected by the extirpation scaling factor
; when extirpated, turtles die and exit from the simulation
to extirpate
  ask turtles with [ my-continent = 1 ]
    [
      if random-float 1 < ( extirpation-scaling-factor * (( abs (trait - [ hypsodonty-selection-factor ] of patch-here )) / adaptive-peak-width ))
      [ die ]
    ]

   ask turtles with [ my-continent = 2 ]
     [
      if random-float 1 < ( extirpation-scaling-factor * (( abs (trait - [ hypsodonty-selection-factor ] of patch-here )) / adaptive-peak-width))

         [ die ]
      ]
end

; color patches according to certain variables
to color-patches
  if patch-visualization = "trait-value"
  [ if (count patches with [ any? turtles-here ]) != 0 and ticks != 0
    [ ask patches with [ pcolor != 107 ] with [ average-trait-value != 99 ] [ set pcolor scale-color violet average-trait-value 0 3 ] ] ]

  if patch-visualization = "biome-type"
  [ ask patches
    [
    if biome = "Forest" [ set pcolor 53 ]
    if biome = "Tundra" [ set pcolor 87 ]
    if biome = "Desert" [ set pcolor 47 ]
    if biome = "Grassland" [ set pcolor 67 ]
    ] ]

  if patch-visualization = "ecometric-load"
  [ if (count patches with [ any? turtles-here ]) != 0 and ticks != 0
    [ ask patches with [ pcolor != 107 ] with [ average-trait-value != 99 ]
      [ ifelse ( ecometric-load < 0 )
      [ set pcolor scale-color red ecometric-load -2 0 ]
        [ set pcolor scale-color yellow ecometric-load 0.00000000000000000000000000001 2 ] ] ] ]
  ; if statement: <0 scale with red, >0 scale with yellow

  if patch-visualization = "species-richness"
  [ if (count patches with [ any? turtles-here ]) != 0 and ticks != 0
    [ ask patches with [ pcolor != 107 ] with [ average-trait-value != 99 ] [ set pcolor scale-color magenta species-richness 0 16 ] ] ]

  if patch-visualization = "individual-species-traits"
  [ if (count patches with [ any? turtles-here with [ species = trait-maps-for-individual-species ] ] ) != 0
    [ ask patches with [ pcolor != 107 ] with [ average-trait-value != 99 ] with [ any? turtles-here with [ species = trait-maps-for-individual-species ] ]
      [ set pcolor scale-color violet individual-species-traits 0 3 ] ] ]

  if patch-visualization = "none"
  [ ]
end

; the trait value of the turtle of a certain species is assigned to individual-species-traits for the purposes of visualization
to calculate-individual-species-traits
  ask patches with [ count turtles-here with [ species = trait-maps-for-individual-species ] != 0 ]
  [ set individual-species-traits ( [ trait ] of one-of turtles-here with [ species = trait-maps-for-individual-species ] ) ]
end

; input patch variables (temperature, precipitation, elevation, grit, province, and biome) from a .txt file
to input-geography
  ask patches [ set temperature 999 ]
  file-open "input_geography.txt"
  while [not file-at-end?]
  [
    let next-x file-read
    let next-y file-read
    let next-continent file-read
    ask patch next-x next-y [ set continent next-continent ]
    let next-temperature file-read
    ask patch next-x next-y [set temperature next-temperature]
    let next-precipitation file-read
    ask patch next-x next-y [set precipitation next-precipitation]
    let next-elevation file-read
    ask patch next-x next-y [set elevation next-elevation]
    let next-grit file-read
    ask patch next-x next-y [set grit next-grit]
    let next-province file-read
    ask patch next-x next-y [ set province next-province ]
    let next-biome file-read-line
    ask patch next-x next-y [ set biome next-biome]
  ]
  file-close
  ask patches with [ temperature = 999 ] [ set pcolor 107 ]
  ask patches with [ temperature != 999 ]
  [ set precipitation ( precipitation + 100 )
    set pcolor 52 ]

  calculate-biomes
end

; at the beginning of the model, this function is called to simulate the first speciation event, in which the first turtle species gives rise to the second turtle species
to first-speciation
  if which-continent = "Hesperia" or which-continent = "Both" [
  set center-xcor ( mean [ xcor ] of turtles with [ species = 1 ] )
  set center-ycor ( mean [ ycor ] of turtles with [ species = 1 ] )
  set center (patch center-xcor center-ycor)
  set farthest-turtle max-one-of (turtles with [ species = 1 ]) [ distance center ]
  ask farthest-turtle
    [ hatch 1
      [ set species 2
        ] ] ]

  if which-continent = "Vostochnia" or which-continent = "Both" [
  set center-xcor ( mean [ xcor ] of turtles with [ species = 31 ] )
  set center-ycor ( mean [ ycor ] of turtles with [ species = 31 ] )
  set center (patch center-xcor center-ycor)
  set farthest-turtle max-one-of (turtles with [ species = 31 ]) [ distance center ]
  ask farthest-turtle
    [ hatch 1
      [ set species 32
        ] ] ]
end

; to create a list of what species currently exist in the model
to count-species
  ; create list of what species exist
  set species-list [ ]
  foreach [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 ] [ y ->
    if any? turtles with [ species = y ] [ set species-list lput y species-list ] ]
end

; for all other speciation events after the first speciation event
; iterates through all existing species listed in species-list
; finds the most distant (Euclidean distance) population from the mean x and y coordinates of all populations of the species
; that most distant population gives rise to a population of a new species
to other-speciations
  if which-continent = "Hesperia" or which-continent = "Both" [
    ifelse empty? species-list [ ] [
  foreach species-list [ x ->
  set center-xcor ( mean [ xcor ] of turtles with [ species = x ] )
  set center-ycor ( mean [ ycor ] of turtles with [ species = x ] )
  set center (patch center-xcor center-ycor)
  set farthest-turtle max-one-of (turtles with [ species = x ]) [ distance center ]
  ask farthest-turtle
      [ hatch 1
      [ set species ( 2 * x + 1 ) ] ; new species
  ask turtles with [ species = x ] [ set species (2 * x + 2 ) ] ] ] ] ] ; old species
end






;;; reporters

to count-number-of-existing-species
    foreach [ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 ] [ a ->
      if any? (turtles with [ species = a ]) [ set existing-species existing-species + 1 ] ]
end

to-report hesperia-trait-mean
  report mean [ average-trait-value ] of patches with [ continent = 1 and any? turtles-here ]
end

to-report hesperia-trait-sd
  report standard-deviation [ average-trait-value ] of patches with [ continent = 1 and (count turtles-here) > 1 ]
end

to-report hesperia-el-mean
  report mean [ ecometric-load ] of patches with [ continent = 1 and any? turtles-here ]
end

to-report hesperia-el-sd
  report standard-deviation [ ecometric-load ] of patches with [ continent = 1 and (count turtles-here) > 1 ]
end

to final-images ; used to generate PNG files of the continents with patches colored according to certain variables

  set patch-visualization "trait-value"
  calculate-average-trait-value-for-patches
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  color-patches
  export-interface "file/path/here/trait_value.png"

  set patch-visualization "ecometric-load"
  calculate-ecometric-load
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  color-patches
  export-view "file/path/here/ecometric_load.png"

  set patch-visualization "species-richness"
  calculate-species-richness
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  color-patches
  export-view "file/path/here/species_richness.png"

  set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 15
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s15.png"

  set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 16
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s16.png"

  set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 17
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s17.png"

  set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 18
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s18.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 19
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s19.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 20
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s20.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 21
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s21.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 22
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s22.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 23
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s23.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 24
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s24.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 25
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s25.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 26
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s26.png"

    set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 27
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s27.png"

  set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 28
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s28.png"

  set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 29
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s29.png"

  set patch-visualization "individual-species-traits"
  set trait-maps-for-individual-species 30
  ask patches with [ continent = 1 or continent = 2 ] [ set pcolor green ]
  calculate-individual-species-traits
  color-patches
  export-view "file/path/here/s30.png"

  set patch-visualization "trait-value"
  ask patches with [ continent = 1 or continent = 2 ] [ set average-trait-value hypsodonty-selection-factor ]
  color-patches
  export-interface "file/path/here/ideal_trait_value.png"
end

; More BehaviorSpace reporters. These have been commented out to improve the navigability of the procedures in the drop-down menu.

;; existence of species
;to-report existing-s1 ifelse any? turtles with [ species = 1 ] [ report 1 ] [ report 0 ] end
;to-report existing-s2 ifelse any? turtles with [ species = 2 ] [ report 1 ] [ report 0 ] end
;to-report existing-s3 ifelse any? turtles with [ species = 3 ] [ report 1 ] [ report 0 ] end
;to-report existing-s4 ifelse any? turtles with [ species = 4 ] [ report 1 ] [ report 0 ] end
;to-report existing-s5 ifelse any? turtles with [ species = 5 ] [ report 1 ] [ report 0 ] end
;to-report existing-s6 ifelse any? turtles with [ species = 6 ] [ report 1 ] [ report 0 ] end
;to-report existing-s7 ifelse any? turtles with [ species = 7 ] [ report 1 ] [ report 0 ] end
;to-report existing-s8 ifelse any? turtles with [ species = 8 ] [ report 1 ] [ report 0 ] end
;to-report existing-s9 ifelse any? turtles with [ species = 9 ] [ report 1 ] [ report 0 ] end
;to-report existing-s10 ifelse any? turtles with [ species = 10 ] [ report 1 ] [ report 0 ] end
;to-report existing-s11 ifelse any? turtles with [ species = 11 ] [ report 1 ] [ report 0 ] end
;to-report existing-s12 ifelse any? turtles with [ species = 12 ] [ report 1 ] [ report 0 ] end
;to-report existing-s13 ifelse any? turtles with [ species = 13 ] [ report 1 ] [ report 0 ] end
;to-report existing-s14 ifelse any? turtles with [ species = 14 ] [ report 1 ] [ report 0 ] end
;to-report existing-s15 ifelse any? turtles with [ species = 15 ] [ report 1 ] [ report 0 ] end
;to-report existing-s16 ifelse any? turtles with [ species = 16 ] [ report 1 ] [ report 0 ] end
;to-report existing-s17 ifelse any? turtles with [ species = 17 ] [ report 1 ] [ report 0 ] end
;to-report existing-s18 ifelse any? turtles with [ species = 18 ] [ report 1 ] [ report 0 ] end
;to-report existing-s19 ifelse any? turtles with [ species = 19 ] [ report 1 ] [ report 0 ] end
;to-report existing-s20 ifelse any? turtles with [ species = 20 ] [ report 1 ] [ report 0 ] end
;to-report existing-s21 ifelse any? turtles with [ species = 21 ] [ report 1 ] [ report 0 ] end
;to-report existing-s22 ifelse any? turtles with [ species = 22 ] [ report 1 ] [ report 0 ] end
;to-report existing-s23 ifelse any? turtles with [ species = 23 ] [ report 1 ] [ report 0 ] end
;to-report existing-s24 ifelse any? turtles with [ species = 24 ] [ report 1 ] [ report 0 ] end
;to-report existing-s25 ifelse any? turtles with [ species = 25 ] [ report 1 ] [ report 0 ] end
;to-report existing-s26 ifelse any? turtles with [ species = 26 ] [ report 1 ] [ report 0 ] end
;to-report existing-s27 ifelse any? turtles with [ species = 27 ] [ report 1 ] [ report 0 ] end
;to-report existing-s28 ifelse any? turtles with [ species = 28 ] [ report 1 ] [ report 0 ] end
;to-report existing-s29 ifelse any? turtles with [ species = 29 ] [ report 1 ] [ report 0 ] end
;to-report existing-s30 ifelse any? turtles with [ species = 30 ] [ report 1 ] [ report 0 ] end
;
;; mean ecometric load of species
;to-report el-1 if any? turtles with [ species = 1 ] [ report mean [ ecometric-load ] of turtles with [ species = 1 ] ] end
;to-report el-2 if any? turtles with [ species = 2 ] [ report mean [ ecometric-load ] of turtles with [ species = 2 ] ] end
;to-report el-3 if any? turtles with [ species = 3 ] [ report mean [ ecometric-load ] of turtles with [ species = 3 ] ] end
;to-report el-4 if any? turtles with [ species = 4 ] [ report mean [ ecometric-load ] of turtles with [ species = 4 ] ] end
;to-report el-5 if any? turtles with [ species = 5 ] [ report mean [ ecometric-load ] of turtles with [ species = 5 ] ] end
;to-report el-6 if any? turtles with [ species = 6 ] [ report mean [ ecometric-load ] of turtles with [ species = 6 ] ] end
;to-report el-7 if any? turtles with [ species = 7 ] [ report mean [ ecometric-load ] of turtles with [ species = 7 ] ] end
;to-report el-8 if any? turtles with [ species = 8 ] [ report mean [ ecometric-load ] of turtles with [ species = 8 ] ] end
;to-report el-9 if any? turtles with [ species = 9 ] [ report mean [ ecometric-load ] of turtles with [ species = 9 ] ] end
;to-report el-10 if any? turtles with [ species = 10 ] [ report mean [ ecometric-load ] of turtles with [ species = 10 ] ] end
;to-report el-11 if any? turtles with [ species = 11 ] [ report mean [ ecometric-load ] of turtles with [ species = 11 ] ] end
;to-report el-12 if any? turtles with [ species = 12 ] [ report mean [ ecometric-load ] of turtles with [ species = 12 ] ] end
;to-report el-13 if any? turtles with [ species = 13 ] [ report mean [ ecometric-load ] of turtles with [ species = 13 ] ] end
;to-report el-14 if any? turtles with [ species = 14 ] [ report mean [ ecometric-load ] of turtles with [ species = 14] ] end
;to-report el-15 if any? turtles with [ species = 15 ] [ report mean [ ecometric-load ] of turtles with [ species = 15 ] ] end
;to-report el-16 if any? turtles with [ species = 16 ] [ report mean [ ecometric-load ] of turtles with [ species = 16 ] ] end
;to-report el-17 if any? turtles with [ species = 17 ] [ report mean [ ecometric-load ] of turtles with [ species = 17 ] ] end
;to-report el-18 if any? turtles with [ species = 18 ] [ report mean [ ecometric-load ] of turtles with [ species = 18 ] ] end
;to-report el-19 if any? turtles with [ species = 19 ] [ report mean [ ecometric-load ] of turtles with [ species = 19 ] ] end
;to-report el-20 if any? turtles with [ species = 20 ] [ report mean [ ecometric-load ] of turtles with [ species = 20 ] ] end
;to-report el-21 if any? turtles with [ species = 21 ] [ report mean [ ecometric-load ] of turtles with [ species = 21 ] ] end
;to-report el-22 if any? turtles with [ species = 22 ] [ report mean [ ecometric-load ] of turtles with [ species = 22 ] ] end
;to-report el-23 if any? turtles with [ species = 23 ] [ report mean [ ecometric-load ] of turtles with [ species = 23 ] ] end
;to-report el-24 if any? turtles with [ species = 24 ] [ report mean [ ecometric-load ] of turtles with [ species = 24 ] ] end
;to-report el-25 if any? turtles with [ species = 25 ] [ report mean [ ecometric-load ] of turtles with [ species = 25 ] ] end
;to-report el-26 if any? turtles with [ species = 26 ] [ report mean [ ecometric-load ] of turtles with [ species = 26 ] ] end
;to-report el-27 if any? turtles with [ species = 27 ] [ report mean [ ecometric-load ] of turtles with [ species = 27 ] ] end
;to-report el-28 if any? turtles with [ species = 28 ] [ report mean [ ecometric-load ] of turtles with [ species = 28 ] ] end
;to-report el-29 if any? turtles with [ species = 29 ] [ report mean [ ecometric-load ] of turtles with [ species = 29 ] ] end
;to-report el-30 if any? turtles with [ species = 30 ] [ report mean [ ecometric-load ] of turtles with [ species = 30 ] ] end
;; el-1 el-2 el-3 el-4 el-5 el-6 el-7 el-8 el-9 el-10 el-11 el-12 el-13 el-14 el-15 el-16 el-17 el-18 el-19 el-20 el-21 el-22 el-23 el-24 el-25 el-26 el-27 el-28 el-29 el-30
;
;; sd ecometric-load of species
;to-report el-sd-1 if any? turtles with [ species = 1 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 1 ] ] end
;to-report el-sd-2 if any? turtles with [ species = 2 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 2 ] ] end
;to-report el-sd-3 if any? turtles with [ species = 3 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 3 ] ] end
;to-report el-sd-4 if any? turtles with [ species = 4 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 4 ] ] end
;to-report el-sd-5 if any? turtles with [ species = 5 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 5 ] ] end
;to-report el-sd-6 if any? turtles with [ species = 6 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 6 ] ] end
;to-report el-sd-7 if any? turtles with [ species = 7 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 7 ] ] end
;to-report el-sd-8 if any? turtles with [ species = 8 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 8 ] ] end
;to-report el-sd-9 if any? turtles with [ species = 9 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 9 ] ] end
;to-report el-sd-10 if any? turtles with [ species = 10 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 10 ] ] end
;to-report el-sd-11 if any? turtles with [ species = 11 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 11 ] ] end
;to-report el-sd-12 if any? turtles with [ species = 12 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 12 ] ] end
;to-report el-sd-13 if any? turtles with [ species = 13 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 13 ] ] end
;to-report el-sd-14 if any? turtles with [ species = 14 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 14] ] end
;to-report el-sd-15 if any? turtles with [ species = 15 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 15 ] ] end
;to-report el-sd-16 if any? turtles with [ species = 16 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 16 ] ] end
;to-report el-sd-17 if any? turtles with [ species = 17 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 17 ] ] end
;to-report el-sd-18 if any? turtles with [ species = 18 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 18 ] ] end
;to-report el-sd-19 if any? turtles with [ species = 19 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 19 ] ] end
;to-report el-sd-20 if any? turtles with [ species = 20 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 20 ] ] end
;to-report el-sd-21 if any? turtles with [ species = 21 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 21 ] ] end
;to-report el-sd-22 if any? turtles with [ species = 22 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 22 ] ] end
;to-report el-sd-23 if any? turtles with [ species = 23 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 23 ] ] end
;to-report el-sd-24 if any? turtles with [ species = 24 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 24 ] ] end
;to-report el-sd-25 if any? turtles with [ species = 25 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 25 ] ] end
;to-report el-sd-26 if any? turtles with [ species = 26 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 26 ] ] end
;to-report el-sd-27 if any? turtles with [ species = 27 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 27 ] ] end
;to-report el-sd-28 if any? turtles with [ species = 28 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 28 ] ] end
;to-report el-sd-29 if any? turtles with [ species = 29 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 29 ] ] end
;to-report el-sd-30 if any? turtles with [ species = 30 ] [ report standard-deviation [ ecometric-load ] of turtles with [ species = 30 ] ] end
;; el-sd-1 el-sd-2 el-sd-3 el-sd-4 el-sd-5 el-sd-6 el-sd-7 el-sd-8 el-sd-9 el-sd-10 el-sd-11 el-sd-12 el-sd-13 el-sd-14 el-sd-15 el-sd-16 el-sd-17 el-sd-18 el-sd-19 el-sd-20 el-sd-21 el-sd-22 el-sd-23 el-sd-24 el-sd-25 el-sd-26 el-sd-27 el-sd-28 el-sd-29 el-sd-30
;
;; mean average-trait-value of turtles
;to-report atv-1 if any? turtles with [ species = 1 ] [ report mean [ average-trait-value ] of turtles with [ species = 1 ] ] end
;to-report atv-2 if any? turtles with [ species = 2 ] [ report mean [ average-trait-value ] of turtles with [ species = 2 ] ] end
;to-report atv-3 if any? turtles with [ species = 3 ] [ report mean [ average-trait-value ] of turtles with [ species = 3 ] ] end
;to-report atv-4 if any? turtles with [ species = 4 ] [ report mean [ average-trait-value ] of turtles with [ species = 4 ] ] end
;to-report atv-5 if any? turtles with [ species = 5 ] [ report mean [ average-trait-value ] of turtles with [ species = 5 ] ] end
;to-report atv-6 if any? turtles with [ species = 6 ] [ report mean [ average-trait-value ] of turtles with [ species = 6 ] ] end
;to-report atv-7 if any? turtles with [ species = 7 ] [ report mean [ average-trait-value ] of turtles with [ species = 7 ] ] end
;to-report atv-8 if any? turtles with [ species = 8 ] [ report mean [ average-trait-value ] of turtles with [ species = 8 ] ] end
;to-report atv-9 if any? turtles with [ species = 9 ] [ report mean [ average-trait-value ] of turtles with [ species = 9 ] ] end
;to-report atv-10 if any? turtles with [ species = 10 ] [ report mean [ average-trait-value ] of turtles with [ species = 10 ] ] end
;to-report atv-11 if any? turtles with [ species = 11 ] [ report mean [ average-trait-value ] of turtles with [ species = 11 ] ] end
;to-report atv-12 if any? turtles with [ species = 12 ] [ report mean [ average-trait-value ] of turtles with [ species = 12 ] ] end
;to-report atv-13 if any? turtles with [ species = 13 ] [ report mean [ average-trait-value ] of turtles with [ species = 13 ] ] end
;to-report atv-14 if any? turtles with [ species = 14 ] [ report mean [ average-trait-value ] of turtles with [ species = 14 ] ] end
;to-report atv-15 if any? turtles with [ species = 15 ] [ report mean [ average-trait-value ] of turtles with [ species = 15 ] ] end
;to-report atv-16 if any? turtles with [ species = 16 ] [ report mean [ average-trait-value ] of turtles with [ species = 16 ] ] end
;to-report atv-17 if any? turtles with [ species = 17 ] [ report mean [ average-trait-value ] of turtles with [ species = 17 ] ] end
;to-report atv-18 if any? turtles with [ species = 18 ] [ report mean [ average-trait-value ] of turtles with [ species = 18 ] ] end
;to-report atv-19 if any? turtles with [ species = 19 ] [ report mean [ average-trait-value ] of turtles with [ species = 19 ] ] end
;to-report atv-20 if any? turtles with [ species = 20 ] [ report mean [ average-trait-value ] of turtles with [ species = 20 ] ] end
;to-report atv-21 if any? turtles with [ species = 21 ] [ report mean [ average-trait-value ] of turtles with [ species = 21 ] ] end
;to-report atv-22 if any? turtles with [ species = 22 ] [ report mean [ average-trait-value ] of turtles with [ species = 22 ] ] end
;to-report atv-23 if any? turtles with [ species = 23 ] [ report mean [ average-trait-value ] of turtles with [ species = 23 ] ] end
;to-report atv-24 if any? turtles with [ species = 24 ] [ report mean [ average-trait-value ] of turtles with [ species = 24 ] ] end
;to-report atv-25 if any? turtles with [ species = 25 ] [ report mean [ average-trait-value ] of turtles with [ species = 25 ] ] end
;to-report atv-26 if any? turtles with [ species = 26 ] [ report mean [ average-trait-value ] of turtles with [ species = 26 ] ] end
;to-report atv-27 if any? turtles with [ species = 27 ] [ report mean [ average-trait-value ] of turtles with [ species = 27 ] ] end
;to-report atv-28 if any? turtles with [ species = 28 ] [ report mean [ average-trait-value ] of turtles with [ species = 28 ] ] end
;to-report atv-29 if any? turtles with [ species = 29 ] [ report mean [ average-trait-value ] of turtles with [ species = 29 ] ] end
;to-report atv-30 if any? turtles with [ species = 30 ] [ report mean [ average-trait-value ] of turtles with [ species = 30 ] ] end
;
;; sd of average-trait-value of species
;to-report atv-sd-1 if any? turtles with [ species = 1 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 1 ] ] end
;to-report atv-sd-2 if any? turtles with [ species = 2 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 2 ] ] end
;to-report atv-sd-3 if any? turtles with [ species = 3 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 3 ] ] end
;to-report atv-sd-4 if any? turtles with [ species = 4 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 4 ] ] end
;to-report atv-sd-5 if any? turtles with [ species = 5 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 5 ] ] end
;to-report atv-sd-6 if any? turtles with [ species = 6 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 6 ] ] end
;to-report atv-sd-7 if any? turtles with [ species = 7 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 7 ] ] end
;to-report atv-sd-8 if any? turtles with [ species = 8 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 8 ] ] end
;to-report atv-sd-9 if any? turtles with [ species = 9 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 9 ] ] end
;to-report atv-sd-10 if any? turtles with [ species = 10 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 10 ] ] end
;to-report atv-sd-11 if any? turtles with [ species = 11 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 11 ] ] end
;to-report atv-sd-12 if any? turtles with [ species = 12 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 12 ] ] end
;to-report atv-sd-13 if any? turtles with [ species = 13 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 13 ] ] end
;to-report atv-sd-14 if any? turtles with [ species = 14 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 14 ] ] end
;to-report atv-sd-15 if any? turtles with [ species = 15 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 15 ] ] end
;to-report atv-sd-16 if any? turtles with [ species = 16 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 16 ] ] end
;to-report atv-sd-17 if any? turtles with [ species = 17 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 17 ] ] end
;to-report atv-sd-18 if any? turtles with [ species = 18 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 18 ] ] end
;to-report atv-sd-19 if any? turtles with [ species = 19 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 19 ] ] end
;to-report atv-sd-20 if any? turtles with [ species = 20 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 20 ] ] end
;to-report atv-sd-21 if any? turtles with [ species = 21 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 21 ] ] end
;to-report atv-sd-22 if any? turtles with [ species = 22 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 22 ] ] end
;to-report atv-sd-23 if any? turtles with [ species = 23 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 23 ] ] end
;to-report atv-sd-24 if any? turtles with [ species = 24 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 24 ] ] end
;to-report atv-sd-25 if any? turtles with [ species = 25 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 25 ] ] end
;to-report atv-sd-26 if any? turtles with [ species = 26 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 26 ] ] end
;to-report atv-sd-27 if any? turtles with [ species = 27 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 27 ] ] end
;to-report atv-sd-28 if any? turtles with [ species = 28 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 28 ] ] end
;to-report atv-sd-29 if any? turtles with [ species = 29 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 29 ] ] end
;to-report atv-sd-30 if any? turtles with [ species = 30 ] [ report standard-deviation [ average-trait-value ] of turtles with [ species = 30 ] ] end
;
;to-report desert-biome
;  report count patches with [ continent = 1 and biome = "Desert" ]
;end
;
;to-report forest-biome
;  report count patches with [ continent = 1 and biome = "Forest" ]
;end
;
;to-report grassland-biome
;  report count patches with [ continent = 1 and biome = "Grassland" ]
;end
;
;to-report tundra-biome
;  report count patches with [ continent = 1 and biome = "Tundra" ]
;end
@#$#@#$#@
GRAPHICS-WINDOW
27
10
575
559
-1
-1
9.0
1
10
1
1
1
0
0
0
1
0
59
0
59
0
0
1
ticks
30.0

BUTTON
613
19
679
52
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
692
18
755
51
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
768
18
848
51
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
618
95
813
128
dispersal-probability
dispersal-probability
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
616
59
845
92
adaptive-peak-width
adaptive-peak-width
0.1
3
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
615
137
844
170
extirpation-scaling-factor
extirpation-scaling-factor
0
3
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
615
174
796
207
phenotypic-variance
phenotypic-variance
0.01
0.2
0.05
0.01
1
NIL
HORIZONTAL

PLOT
620
431
816
584
number of turtles
ticks
turtles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"hesperia" 1.0 0 -16777216 true "" "plot count turtles with [ continent = 1 ]"
"vostochnia" 1.0 0 -2674135 true "" "plot count turtles with [ continent = 2 ]"

CHOOSER
615
260
836
305
patch-visualization
patch-visualization
"biome-type" "province" "ecometric-load" "trait-value" "species-richness" "individual-species-traits" "none"
6

TEXTBOX
585
328
735
346
NIL
12
0.0
1

CHOOSER
617
318
721
363
which-continent
which-continent
"Hesperia" "Vostochnia" "Both"
0

MONITOR
866
19
941
64
species 1
count turtles with [ species = 1 ]
17
1
11

MONITOR
947
19
1022
64
species 2
count turtles with [ species = 2 ]
17
1
11

MONITOR
1026
20
1101
65
species 3
count turtles with [ species = 3 ]
17
1
11

MONITOR
1106
21
1181
66
species 4
count turtles with [ species = 4 ]
17
1
11

MONITOR
1184
22
1251
67
species 5
count turtles with [ species = 5 ]
17
1
11

MONITOR
1254
22
1323
67
species 6
count turtles with [ species = 6 ]
17
1
11

MONITOR
1325
22
1391
67
species 7
count turtles with [ species = 7 ]
17
1
11

MONITOR
1396
22
1471
67
species 8
count turtles with [ species = 8 ]
17
1
11

MONITOR
866
70
941
115
species 9
count turtles with [ species = 9 ]
17
1
11

MONITOR
945
70
1027
115
species 10
count turtles with [ species = 10 ]
17
1
11

MONITOR
1031
71
1113
116
species 11
count turtles with [ species = 11 ]
17
1
11

MONITOR
1116
71
1198
116
species 12
count turtles with [ species = 12 ]
17
1
11

MONITOR
1209
69
1291
114
species 13
count turtles with [ species = 13 ]
17
1
11

MONITOR
1295
71
1377
116
species 14
count turtles with [ species = 14 ]
17
1
11

MONITOR
869
121
951
166
species 15
count turtles with [ species = 15 ]
17
1
11

MONITOR
955
121
1037
166
species 16
count turtles with [ species = 16 ]
17
1
11

CHOOSER
619
374
831
419
trait-maps-for-individual-species
trait-maps-for-individual-species
15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
13

MONITOR
1040
121
1122
166
species 17
count turtles with [ species = 17 ]
17
1
11

MONITOR
1125
122
1207
167
species 18
count turtles with [ species = 18 ]
17
1
11

MONITOR
1212
122
1294
167
species 19
count turtles with [ species = 19 ]
17
1
11

MONITOR
1301
122
1383
167
species 20
count turtles with [ species = 20 ]
17
1
11

SWITCH
725
323
847
356
hide-turtles
hide-turtles
0
1
-1000

MONITOR
871
170
953
215
species 21
count turtles with [ species = 21 ]
17
1
11

MONITOR
961
171
1043
216
species 22
count turtles with [ species = 22 ]
17
1
11

MONITOR
1048
173
1130
218
species 23
count turtles with [ species = 23 ]
17
1
11

MONITOR
1134
173
1216
218
species 24
count turtles with [ species = 24 ]
17
1
11

MONITOR
1221
174
1303
219
species 25
count turtles with [ species = 25 ]
17
1
11

MONITOR
1306
174
1388
219
species 26
count turtles with [ species = 26 ]
17
1
11

MONITOR
874
222
956
267
species 27
count turtles with [ species = 27 ]
17
1
11

MONITOR
961
222
1043
267
species 28
count turtles with [ species = 28 ]
17
1
11

MONITOR
1045
222
1127
267
species 29
count turtles with [ species = 29 ]
17
1
11

MONITOR
1130
223
1212
268
species 30
count turtles with [ species = 30 ]
17
1
11

MONITOR
1042
477
1173
522
NIL
hesperia-extinctions
17
1
11

MONITOR
1039
530
1190
575
Number of dispersals
number-of-dispersals
0
1
11

SWITCH
874
291
1036
324
climate-change?
climate-change?
0
1
-1000

PLOT
826
432
1026
582
mean average trait value hesperia
ticks
mean atv
0.0
400.0
0.0
3.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ average-trait-value ] of patches with [ continent = 1 and any? turtles-here ]"

MONITOR
1217
222
1341
267
NIL
existing-species
17
1
11

SWITCH
871
336
1012
369
export-view?
export-view?
1
1
-1000

SLIDER
613
212
785
245
heritability
heritability
0
1
0.5
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
This NetLogo model simulates trait-based biotic responses to climate change in an environmentally heterogeneous continent in an evolving clade, the species of which are each represented by local populations that disperse and interbreed; they also are subject to selection, genetic drift, and local extirpation. We simulated mammalian herbivores, whose success depends on tooth crown height, vegetation type, precipitation and grit. This model investigates the role of dispersal, selection, extirpation, and other factors contribute to resilience under three climate change scenarios.

# Model overview
This agent-based model (ABM) simulates trait-based population-level responses to
climatic and environmental change. The premise of ABMs lies in the principle that micro-level agent-agent and agent-environment interactions produce emergent macro-level outcomes for systems too complex or too specific to model with standard structural equations (Tisue & Wilensky, 2004). Our rule-based ABM simulates the fates of metapopulations whose fitness is controlled by an evolving functional trait that responds to selection based on environmental conditions. Functional traits are phenotypic characteristics that interface with the environment (McGill et al., 2006; Polly et al., 2016). Environmental change potentially affects trait performance and population fitness, consequently driving trait evolution or population extinction., which in turn affects functional trait distribution in local community assemblages
(Jønsson et al., 2015; Morales-Castilla et al., 2015; Polly & Head, 2015).

The functional trait modeled is tooth crown height of mammalian herbivores, such as
horses. The evolution of high-crowned teeth in these herbivores is climatically driven; in fact, the relationship between crown height, environment, and climate is well-understood both functionally and evolutionarily (Damuth & Janis, 2011; Eronen et al., 2010; Fortelius et al., 2002; King et al., 2005; Semprebon et al., 2019). In environments with abrasive or dusty/gritty vegetation, higher-crowned (hypsodont) teeth provide greater fitness despite the metabolic and mineral costs of producing them. The silica content of grass and gritty arid environments select for hypsodonty; non-gritty forests select for brachydonty (low-crowned teeth). Although the specifics of our model are teeth, diet, and environment, the implementation is abstract enough that results can be generalized to other climate-environment-trait systems.

Our virtual world consists of a continent that is gridded in spatially distinct habitat “patches.” Each patch denotes a local environment, which determines the local fitness optimum for inhabitant populations. Each “agent” in this model represents one local population of a species. Each species can consist of many populations, each of which occupies a single patch, thus making them the equivalent of metapopulations (sensu Hanski, 1999). A patch can be occupied by a maximum of one agent of any given species—the same patch can be occupied by multiple agents, given that the agents are of different species. Each individual run is divided into temporally distinct “time steps.”

Our model incorporates five key processes: climate change, dispersal (including gene
flow), selection, speciation, and extirpation. Model parameters can be adjusted for each of these mechanisms except for speciation, which we treat as a constant process so that our model runs end with a predictable number of species with identical patterns of common ancestry and divergence times so that variance between model runs is due only to change in climate and the aforementioned controllable demographic parameters. Populations do not compete with one another; similarly, this helps the model largely focus on population-environment interactions in a changing climate. During each time step, each local population undergoes selection, dispersal, and the possibility of extirpation. (Populations also undergo genetic drift.) Speciation events act
at predetermined time steps. Additionally, climate change periodically produces shifts in
precipitation and biome type that influence the selective optimum for patches. The crux of the model lies in the interaction of these mechanisms. Adjusting parameters either independently or simultaneously allows us to test which combinations confer resilience under gradual, moderate, or rapid climatic change scenarios. For the purposes of this model, we measure resilience via three metrics: number of species existing at the end of each model run (species number), number of populations of each species (species abundance), and successful colonization of new biomes that arise during the run.

Our ABM extends Polly et al. (2016)’s trait-climate-environment model in two important
ways. This model integrates climate change and dynamic environments; the previous model was limited to static environments. Additionally, we have ported the model to NetLogo 6.1.1. Underlying mechanics remain consistent with the earlier model. Readers are referred to it for full justification of implementation and parameter choices.

## NetLogo
NetLogo is an ABM programming environment suitable for simulating spatially and
temporally explicit phenomena (Tisue & Wilensky, 2004; Wilensky, 1999). Spatial settings and rules for agent behavior are highly customizable (Tisue & Wilensky, 2004). We used NetLogo’s BehaviorSpace tool to record the numerical output of each model run; spatial results were identified through model interface images.

## Model algorithm
Each individual run lasts for 400 time-steps. Several parameters—selection intensity
(adaptive peak width), phenotypic variance, trait heritability, dispersal probability, and extirpation probability—can be adjusted in the setup. Populations undergo extirpation, dispersal, selection, gene flow, and genetic drift every time step; speciation occurs every 100 steps.

## Model world and characteristics of patches
The model world consists of the virtual continent, Hesperia, with varied topography.
Hesperia is divided into 822 spatially distinct square patches, each of which is assigned values for grit, temperature, and mean annual precipitation. Patches are categorized into vegetative biomes (tundra, forest, desert, or grassland) based on temperature and precipitation (Whittaker, 1967). In this way, Hesperia is environmentally heterogeneous. Local selective optimums for hypsodonty values are calculated based on grit, precipitation, and biome type. Climate becomes more arid as the model progresses, transforming forest into grassland and desert and shifting
selective optimums.

We determined biome type (grassland, tundra, forest, or desert) from a function of
temperature and precipitation following Whitaker (1967). If temperature ≤ -5 °C, the patch is categorized as tundra biome. If temperature > -5 °C and precipitation ≤ 20 cm/year, the patch biome is categorized as desert. If temperature ≥ 5 °C and precipitation > 20 cm but ≤ 90 cm, the biome is categorized as grassland. All other patches are classified as forest biomes.

## Characteristics of populations
Each local population is represented in NetLogo using an agent called a “turtle.” Each
population is assigned numerical characteristics: ID number, species assignment, trait value, and population size (number of individuals, which determines rate of genetic drift). Population trait value represents the population mean. For consistency with the 2016 model, population size is set to 100 individuals. Names assigned to species in the model output indicate species ancestry and the model step at which it originated.

## Functional trait and its local optimum
Tooth crown height is our functional trait. In mammals, crown height varies with
environmental parameters affecting diet abrasiveness. The selective optimum (ideal trait value) in any local environment (patch) is a function of grit g, precipitation p, and biome b. The optimum ranged from 0 (low-crowned or brachydont) to 3 (high-crowned or hypsodont). Highcrowned teeth are more suited to dry and gritty environments and tough vegetation; in contrast, low-crowned teeth are more suited to wet environments with little grit and tender vegetation (Janis and Fortelius, 1988; Damuth and Janus, 2011). Following Polly et al. (2016), the local selective optimum, 𝜃i, for each patch was set as a function of precipitation, biome, and grit, where 𝑔 is grit, p is precipitation, and b is biome.
𝜃i = 𝑔 + 𝛿[𝑝] + 𝛿[𝑏] ,
where 𝛿[𝑝] is the piecewise function:
For 𝑝 ≤ 100, 𝛿[𝑝] = 100 - p
For 𝑝 > 100, 𝛿[𝑝] = 0
and 𝛿[𝑏] is the piecewise function:
For b = “forest” or “tundra”, 𝛿[𝑏] = 0
For b = “desert”, 𝛿[𝑏] = 0.5
For b = “grassland”, 𝛿[𝑏] = 1

Population fitness is determined by proximity of mean functional trait value and local
selective optimum of the occupied patch. Smaller differences between the actual and optimal trait value indicate higher fitness.

## Extirpation
Extirpation is the local extinction of a population from a patch. Species extinction occurs if all local populations of the species are extirpated. Extirpation occurs stochastically, with a greater probability p(e) in populations with trait value far from local optimum:

p(e) = ESF * |z - θ_i| / APW

where z is population trait value, θi is local selective optimum, ESF is extirpation scaling factor (a user-controllable parameter ranging from 0 to infinity), and APW is adaptive peak width (selection intensity; see below). Essentially, if trait value is far from the selective optimum relative to selection intensity, extirpation probability increases toward 1.0. Setting ESF < 1 decreases the probability, whereas setting ESF > 1 increases it. This method is comparable to the Lynch and Lande (1993) function and identical to that of Polly et al. (2016).

## Dispersal
During a dispersal event, a turtle creates a copy of itself on an adjacent terrestrial patch. The user-controllable dispersal probability parameter (ranges from 0 to 1) determines probability of dispersal into an individual adjacent terrestrial patch.

## Selection and genetic drift
Each step, the trait value of each population is modified by selection:

z_new = [z_old(θ_i - z_old) / w^2] * h^2 * v

where z_old is trait value before selection, θi is local selective optimum, w^2
is adaptive peak width (equal to standard deviation of the normal curve used to model the adaptive peak), h^2 is heritability, and v is phenotypic variance. This equation, used in Polly et al. (2016), comes from theoretical evolutionary genetics models of adaptive peaks (Arnold et al., 2001; Lande, 1976; Simpson, 1944).

Each trait value is further modified by a neutral genetic drift event. The genetic drift term is randomly chosen from a normal distribution with mean 0 and standard deviation h2 v / N, where h2 is heritability, v is phenotypic variance, and N is population size. This standard deviation derives from Lande (1976). The genetic drift value is added to znew.

## Genetic flow
Each patch can only support one turtle of each species. After dispersal, if two or more
populations of the same species occupy the same patch, gene flow between populations occurs. The amalgamated population takes on the mean of the populations occupying the patch and the local population size is reset to 100.

## Speciation
Speciation via a simplified peripheral isolation model occurs at time-steps 0, 100, 200,
and 300 (Polly et al., 2016). Every species undergoes the same speciation process. First, the most peripheral turtle of each species is determined. The mean x-coordinate (xmean) and mean ycoordinate (ymean) of all turtles of species k represent the geographic center of the species range.

The population located farthest from the center (determined by Euclidean distance) becomes the founder of a new species on the same patch. The “child” population is identical to the “parent.” The four speciation events will result in a maximum of 16 species at the end of the run. Species are named systematically. The progenitor population is designated species 1. The first speciation event creates species 2. For future speciation events, the “child” population is named species (2x + 1), where x is the current species name. The “parent” population is designated species (2x + 2). For example, at 100 time-steps, species 1 produces species 3. All populations of species 1 are relabeled as species 4.

## Tracking variables
Utilizing NetLogo’s BehaviorSpace tool, relevant population-related variables were
recorded during each time-step. For the aggregate of all populations on the continent, the mean trait value and standard deviation of trait value were recorded. On the species level, the number of populations, mean trait value and standard deviation of trait value were recorded. The number of existing species was also tracked.
For each patch, the average trait value of all species, trait value of individual species, and species richness (number of occupant species) were also reported during each time step.
A species was considered to have colonized a region if 5 patches of the region were occupied by run’s end.

## Barriers to dispersal
Barriers to dispersal in our model are emergent properties from the interaction of
environmental parameters, selection intensity, extirpation risk, and dispersal rate. A population can disperse into any adjacent grid cell regardless of the parameters, but if the trait optimum is substantially different in the new location there is a high probability of immediate extirpation because of low fitness. While the mountains are not modeled as physical barriers, they produce environmental barriers because of their rain shadow, grit cloud, and temperature gradient (which along with precipitation determines vegetation biome). If extirpation scaling factor is low or if adaptive peak width is high (i.e., weak selection) an environmental gradient will pose less of a barrier because a poorly adapted population can still survive. Because extirpation is modeled as a probability rather than a certainty, even a step environmental gradient can be breached by chance if the dispersal rate is high enough. Rate of dispersal affects the likelihood of eventual success because it determines the number of times a population ventures into a cell where it has low fitness. The only impassible physical barriers are the oceans at the continental margins.

# Climate change modeling

## Climate change mechanics
We modeled three scenarios of climate change (gradual, moderate, and rapid) by altering
annual precipitation, which influences biome type as well as the local selective optimum. At predetermined time steps, all patches decrease precipitation levels by a preset amount. All model runs, regardless of the rate of climate change, begin and end with all patches on Hesperia having the same environment. Each model starts with high precipitation such that most Hesperian patches possess forest biomes, with few tundra patches at high elevations. By the end of the model, precipitation across all patches decreases by 200 cm and most patches have changed to desert. In the gradual climate change scenario, precipitation decreases 5.13 cm every ten steps, in the moderate scenario it decreases 28.57 cm of the total change every 50 steps, and in the rapid scenario the precipitation decreases 100 cm twice during the run. Minimum precipitation is floored at 0 cm per year. During climate change events, each patch’s biome type is reclassified using the previously described method. Then, the ideal trait value of each patch is also
recalculated.

# Experiments
We conducted four experiments varying demographic parameters, each repeated across
three different climate change scenarios. Experiment A varied dispersal with consistently high
extirpation (DISP varies between 0 and 1.0, APW = 1.0, ESF = 2.0). Experiment B varied
dispersal under consistently low extirpation (DISP varies between 0 and 1.0, APW = 1.0, ESF = 1.0). Experiment C varied ESF under high dispersal (ESF varies between 0 and 2.0, APW = 1.0, and DISP = 1.0). Experiment D varied APW under high ESF and high dispersal (APW varies between 0 and 3.0, ESF = 2.0, DISP = 1.0). An alteration of Experiment D varied APW under low ESF and high dispersal (APW varies between 0 and 3.0, ESF = 1.0, DISP = 1.0). See Extended Results & Figure 3 for selected model output and Files S3 for detailed results on each model run.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="heritability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trait-maps-for-individual-species">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extirpation-scaling-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-visualization">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-continent">
      <value value="&quot;Hesperia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="climate-change?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-turtles">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phenotypic-variance">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-peak-width">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
