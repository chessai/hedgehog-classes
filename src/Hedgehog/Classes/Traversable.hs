{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE LambdaCase #-}

module Hedgehog.Classes.Traversable (traversableLaws) where

import Hedgehog
import Hedgehog.Classes.Common

import Data.Functor.Identity
import Data.Functor.Compose
import Data.Traversable (Traversable(..), foldMapDefault, fmapDefault)

traversableLaws ::
  ( Traversable f
  , forall x. Eq x => Eq (f x), forall x. Show x => Show (f x)
  ) => (forall x. Gen x -> Gen (f x)) -> Laws
traversableLaws gen = Laws "Foldable"
  [ ("Naturality", traversableNaturality gen)
  , ("Identity", traversableIdentity gen)
  , ("Composition", traversableComposition gen)
  , ("Sequence Naturality", traversableSequenceNaturality gen)
  , ("Sequence Identity", traversableSequenceIdentity gen)
  , ("Sequence Composition", traversableSequenceComposition gen)
  , ("foldMap", traversableFoldMap gen)
  , ("fmap", traversableFmap gen)
  ]

type TraversableProp f =
  ( Traversable f
  , forall x. Eq x => Eq (f x), forall x. Show x => Show (f x)
  ) => (forall x. Gen x -> Gen (f x)) -> Property

traversableNaturality :: TraversableProp f
traversableNaturality fgen = property $ do
  a <- forAll $ fgen genSmallInteger
  (apTrans (traverse func4 a)) === (traverse (apTrans . func4) a)

traversableIdentity :: TraversableProp f
traversableIdentity fgen = property $ do
  t <- forAll $ fgen genSmallInteger
  (traverse Identity t) === (Identity t)

traversableComposition :: TraversableProp f
traversableComposition fgen = property $ do
  t <- forAll $ fgen genSmallInteger 
  let x = (traverse (Compose . fmap func5 . func6) t)
  let y = (Compose (fmap (traverse func5) (traverse func6 t)))
  x === y

traversableSequenceNaturality :: TraversableProp f
traversableSequenceNaturality fgen = property $ do
  x <- forAll $ fgen (genCompose genSmallInteger genTriple (genTuple genSetInteger))
  let a = fmap toSpecialApplicative x
  (apTrans (sequenceA a)) === (sequenceA (fmap apTrans a)) 

traversableSequenceIdentity :: TraversableProp f
traversableSequenceIdentity fgen = property $ do
  t <- forAll $ fgen genSmallInteger
  (sequenceA (fmap Identity t)) === (Identity t)

traversableSequenceComposition :: TraversableProp f
traversableSequenceComposition fgen = property $ do
  let genTripleInteger = genTriple genSmallInteger
  t <- forAll $ fgen (genTriple genTripleInteger)
  (sequenceA (fmap Compose t)) === (Compose (fmap sequenceA (sequenceA t)))
  True === True

traversableFoldMap :: TraversableProp f
traversableFoldMap fgen = property $ do
  t <- forAll $ fgen genSmallInteger
  foldMap func3 t === foldMapDefault func3 t  

traversableFmap :: TraversableProp f
traversableFmap fgen = property $ do
  t <- forAll $ fgen genSmallInteger
  fmap func3 t === fmapDefault func3 t  