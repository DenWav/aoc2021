ThisBuild / version := "0.1.0-SNAPSHOT"

ThisBuild / scalaVersion := "3.1.0"

lazy val root = (project in file("."))
  .settings(
    name := "aoc2021day15p1",
    idePackagePrefix := Some("dev.denwav")
  )
