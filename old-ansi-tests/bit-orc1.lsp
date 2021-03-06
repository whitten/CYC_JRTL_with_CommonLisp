;-*- Mode:     Lisp -*-
;;;; Author:   Paul Dietz
;;;; Created:  Sun Jan 26 19:25:28 2003
;;;; Contains: Tests of BIT-ORC1

(in-package :cl-test)

(compile-and-load "bit-aux.lsp")

(deftest bit-orc1.1
  (let* ((s1 (make-array nil :initial-element 0 :element-type 'bit))
	 (s2 (make-array nil :initial-element 0 :element-type 'bit)))
    (values (bit-orc1 s1 s2) s1 s2))
  #0a1
  #0a0
  #0a0)

(deftest bit-orc1.2
  (let* ((s1 (make-array nil :initial-element 1 :element-type 'bit))
	 (s2 (make-array nil :initial-element 0 :element-type 'bit)))
    (values (bit-orc1 s1 s2) s1 s2))
  #0a0
  #0a1
  #0a0)

(deftest bit-orc1.3
  (let* ((s1 (make-array nil :initial-element 0 :element-type 'bit))
	 (s2 (make-array nil :initial-element 1 :element-type 'bit)))
    (values (bit-orc1 s1 s2) s1 s2))
  #0a1
  #0a0
  #0a1)

(deftest bit-orc1.4
  (let* ((s1 (make-array nil :initial-element 1 :element-type 'bit))
	 (s2 (make-array nil :initial-element 1 :element-type 'bit)))
    (values (bit-orc1 s1 s2) s1 s2))
  #0a1
  #0a1
  #0a1)

(deftest bit-orc1.5
  (let* ((s1 (make-array nil :initial-element 0 :element-type 'bit))
	 (s2 (make-array nil :initial-element 0 :element-type 'bit))
	 (s3 (make-array nil :initial-element 0 :element-type 'bit))
	 (result (bit-orc1 s1 s2 s3)))
    (values s1 s2 s3 result (eqt s3 result)))
  #0a0
  #0a0
  #0a1
  #0a1
  t)

(deftest bit-orc1.6
  (let* ((s1 (make-array nil :initial-element 1 :element-type 'bit))
	 (s2 (make-array nil :initial-element 1 :element-type 'bit))
	 (s3 (make-array nil :initial-element 0 :element-type 'bit))
	 (result (bit-orc1 s1 s2 s3)))
    (values s1 s2 s3 result (eqt s3 result)))
  #0a1
  #0a1
  #0a1
  #0a1
  t)

(deftest bit-orc1.7
  (let* ((s1 (make-array nil :initial-element 1 :element-type 'bit))
	 (s2 (make-array nil :initial-element 0 :element-type 'bit))
	 (result (bit-orc1 s1 s2 t)))
    (values s1 s2 result (eqt s1 result)))
  #0a0
  #0a0
  #0a0
  t)


;;; Tests on bit vectors

(deftest bit-orc1.8
  (let ((a1 (copy-seq #*0011))
	(a2 (copy-seq #*0101)))
    (values (check-values (bit-orc1 a1 a2)) a1 a2))
  #*1101 #*0011 #*0101)

(deftest bit-orc1.9
  (let* ((a1 (copy-seq #*0011))
	 (a2 (copy-seq #*0101))
	 (result (check-values (bit-orc1 a1 a2 t))))
    (values result a1 a2 (eqt result a1)))
  #*1101 #*1101 #*0101 t)

(deftest bit-orc1.10
  (let* ((a1 (copy-seq #*0011))
	 (a2 (copy-seq #*0101))
	 (a3 (copy-seq #*1110))
	 (result (check-values (bit-orc1 a1 a2 a3))))
    (values result a1 a2 a3 (eqt result a3)))
  #*1101 #*0011 #*0101 #*1101 t)

(deftest bit-orc1.11
  (let ((a1 (copy-seq #*0011))
	(a2 (copy-seq #*0101)))
    (values (check-values (bit-orc1 a1 a2 nil)) a1 a2))
  #*1101 #*0011 #*0101)

;;; Tests on bit arrays

(deftest bit-orc1.12
  (let* ((a1 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 1)(0 1))))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 0)(1 1))))
	 (result (bit-orc1 a1 a2)))
    (values a1 a2 result))
  #2a((0 1)(0 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1)))

(deftest bit-orc1.13
  (let* ((a1 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 1)(0 1))))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 0)(1 1))))
	 (result (bit-orc1 a1 a2 t)))
    (values a1 a2 result))
  #2a((1 0)(1 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1)))

(deftest bit-orc1.14
  (let* ((a1 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 1)(0 1))))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 0)(1 1))))
	 (result (bit-orc1 a1 a2 nil)))
    (values a1 a2 result))
  #2a((0 1)(0 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1)))

(deftest bit-orc1.15
  (let* ((a1 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 1)(0 1))))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 0)(1 1))))
	 (a3 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 0)(0 0))))
	 (result (bit-orc1 a1 a2 a3)))
    (values a1 a2 a3 result))
  #2a((0 1)(0 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1))
  #2a((1 0)(1 1)))

;;; Adjustable arrays

(deftest bit-orc1.16
  (let* ((a1 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 1)(0 1))
			 :adjustable t))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :initial-contents '((0 0)(1 1))
			 :adjustable t))
	 (result (bit-orc1 a1 a2)))
    (values a1 a2 result))
  #2a((0 1)(0 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1)))

;;; Displaced arrays

(deftest bit-orc1.17
  (let* ((a0 (make-array '(8) :element-type 'bit
			 :initial-contents '(0 1 0 1 0 0 1 1)))
	 (a1 (make-array '(2 2) :element-type 'bit
			 :displaced-to a0
			 :displaced-index-offset 0))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :displaced-to a0
			 :displaced-index-offset 4))
	 (result (bit-orc1 a1 a2)))
    (values a0 a1 a2 result))
  #*01010011
  #2a((0 1)(0 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1)))

(deftest bit-orc1.18
  (let* ((a0 (make-array '(8) :element-type 'bit
			 :initial-contents '(0 1 0 1 0 0 1 1)))
	 (a1 (make-array '(2 2) :element-type 'bit
			 :displaced-to a0
			 :displaced-index-offset 0))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :displaced-to a0
			 :displaced-index-offset 4))
	 (result (bit-orc1 a1 a2 t)))
    (values a0 a1 a2 result))
  #*10110011
  #2a((1 0)(1 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1)))

(deftest bit-orc1.19
  (let* ((a0 (make-array '(12) :element-type 'bit
			 :initial-contents '(0 1 0 1 0 0 1 1 1 1 1 0)))
	 (a1 (make-array '(2 2) :element-type 'bit
			 :displaced-to a0
			 :displaced-index-offset 0))
	 (a2 (make-array '(2 2) :element-type 'bit
			 :displaced-to a0
			 :displaced-index-offset 4))
	 (a3 (make-array '(2 2) :element-type 'bit
			 :displaced-to a0
			 :displaced-index-offset 8))
	 (result (bit-orc1 a1 a2 a3)))
    (values a0 a1 a2 result))
  #*010100111011
  #2a((0 1)(0 1))
  #2a((0 0)(1 1))
  #2a((1 0)(1 1)))

(deftest bit-orc1.20
  (macrolet ((%m (z) z)) (bit-orc1 (expand-in-current-env (%m #*0011)) #*0101))
  #*1101)

(deftest bit-orc1.21
  (macrolet ((%m (z) z)) (bit-orc1 #*1010 (expand-in-current-env (%m #*1100))))
  #*1101)

(deftest bit-orc1.22
  (macrolet ((%m (z) z)) (bit-orc1 #*10100011 #*01101010
				   (expand-in-current-env (%m nil))))
  #*01111110)


(deftest bit-orc1.order.1
  (let* ((s1 (make-array 1 :initial-element 0 :element-type 'bit))
	 (s2 (make-array 1 :initial-element 0 :element-type 'bit))
	 (x 0) y z)
    (values
     (bit-orc1 (progn (setf y (incf x)) s1)
	       (progn (setf z (incf x)) s2))
     x y z))
  #*1 2 1 2)

(deftest bit-orc1.fold.1
  (flet ((%f () (declare (optimize speed (safety 0) (space 0)))
	     (bit-orc1 #*11010 #*10100)))
    (values (%f) (let ((bv (%f))) (setf (elt bv 0) 0) bv) (%f)))
  #*10101 #*00101 #*10101)

;;; Random tests

(deftest bit-orc1.random.1
  (bit-random-test-fn #'bit-orc1 #'logorc1)
  nil)

;;; Error tests

(deftest bit-orc1.error.1
  (signals-error (bit-orc1) program-error)
  t)

(deftest bit-orc1.error.2
  (signals-error (bit-orc1 #*000) program-error)
  t)

(deftest bit-orc1.error.3
  (signals-error (bit-orc1 #*000 #*0100 nil nil)
		 program-error)
  t)


