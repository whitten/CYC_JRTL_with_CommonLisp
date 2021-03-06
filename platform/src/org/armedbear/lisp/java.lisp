;;; java.lisp
;;;
;;; Copyright (C) 2003-2007 Peter Graves, Andras Simon
;;; $Id: java.lisp 12315 2009-12-30 22:46:31Z astalla $
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License
;;; as published by the Free Software Foundation; either version 2
;;; of the License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;;;
;;; As a special exception, the copyright holders of this library give you
;;; permission to link this library with independent modules to produce an
;;; executable, regardless of the license terms of these independent
;;; modules, and to copy and distribute the resulting executable under
;;; terms of your choice, provided that you also meet, for each linked
;;; independent module, the terms and conditions of the license of that
;;; module.  An independent module is a module which is not derived from
;;; or based on this library.  If you modify this library, you may extend
;;; this exception to your version of the library, but you are not
;;; obligated to do so.  If you do not wish to do so, delete this
;;; exception statement from your version.

(in-package "JAVA")

(require "CLOS")

(defun jregister-handler (object event handler &key data count)
  (%jregister-handler object event handler data count))

(defun jinterface-implementation (interface &rest method-names-and-defs)
  "Creates and returns an implementation of a Java interface with
   methods calling Lisp closures as given in METHOD-NAMES-AND-DEFS.

   INTERFACE is either a Java interface or a string naming one.

   METHOD-NAMES-AND-DEFS is an alternating list of method names
   (strings) and method definitions (closures).

   For missing methods, a dummy implementation is provided that
   returns nothing or null depending on whether the return type is
   void or not. This is for convenience only, and a warning is issued
   for each undefined method."
  (let ((interface (jclass interface))
        (implemented-methods
         (loop for m in method-names-and-defs
           for i from 0
           if (evenp i)
           do (assert (stringp m) (m) "Method names must be strings: ~s" m) and collect m
           else
           do (assert (or (symbolp m) (functionp m)) (m) "Methods must be function designators: ~s" m)))
        (null (make-immediate-object nil :ref)))
    (loop for method across
      (jclass-methods interface :declared nil :public t)
      for method-name = (jmethod-name method)
      when (not (member method-name implemented-methods :test #'string=))
      do
      (let* ((void-p (string= (jclass-name (jmethod-return-type method)) "void"))
             (arglist (when (plusp (length (jmethod-params method))) '(&rest ignore)))
             (def `(lambda
                     ,arglist
                     ,(when arglist '(declare (ignore ignore)))
                     ,(if void-p '(values) null))))
        (warn "Implementing dummy method ~a for interface ~a"
              method-name (jclass-name interface))
        (push (coerce def 'function) method-names-and-defs)
        (push method-name method-names-and-defs)))
    (apply #'%jnew-proxy interface method-names-and-defs)))

(defun jmake-invocation-handler (function)
  (%jmake-invocation-handler function))

(when (autoloadp 'jmake-proxy)
  (fmakunbound 'jmake-proxy))

(defgeneric jmake-proxy (interface implementation &optional lisp-this)
  (:documentation "Returns a proxy Java object implementing the provided interface using methods implemented in Lisp - typically closures, but implementations are free to provide other mechanisms. You can pass an optional 'lisp-this' object that will be passed to the implementing methods as their first argument. If you don't provide this object, NIL will be used. The second argument of the Lisp methods is the name of the Java method being implemented. This has the implication that overloaded methods are merged, so you have to manually discriminate them if you want to. The remaining arguments are java-objects wrapping the method's parameters."))

(defmethod jmake-proxy (interface invocation-handler &optional lisp-this)
  "Basic implementation that directly uses an invocation handler."
  (%jmake-proxy (jclass interface) invocation-handler lisp-this))

(defmethod jmake-proxy (interface (implementation function) &optional lisp-this)
  "Implements a Java interface forwarding method calls to a Lisp function."
  (%jmake-proxy (jclass interface) (jmake-invocation-handler implementation) lisp-this))

(defmethod jmake-proxy (interface (implementation package) &optional lisp-this)
  "Implements a Java interface mapping Java method names to symbols in a given package. javaMethodName is mapped to a JAVA-METHOD-NAME symbol. An error is signaled if no such symbol exists in the package, or if the symbol exists but does not name a function."
  (flet ((java->lisp (name)
	   (with-output-to-string (str)
	     (let ((last-lower-p nil))
	       (map nil (lambda (char)
			  (let ((upper-p (char= (char-upcase char) char)))
			    (when (and last-lower-p upper-p)
			      (princ "-" str))
			    (setf last-lower-p (not upper-p))
			    (princ (char-upcase char) str)))
		    name)))))
    (%jmake-proxy (jclass interface)
		  (jmake-invocation-handler 
		   (lambda (obj method &rest args)
		     (let ((sym (find-symbol
				 (java->lisp method)
				 implementation)))
		       (unless sym
			 (error "Symbol ~A, implementation of method ~A, not found in ~A"
				  (java->lisp method)
				  method
				  implementation))
			 (if (fboundp sym)
			     (apply (symbol-function sym) obj method args)
			     (error "Function ~A, implementation of method ~A, not found in ~A"
				    sym method implementation)))))
		  lisp-this)))

(defmethod jmake-proxy (interface (implementation hash-table) &optional lisp-this)
  "Implements a Java interface using closures in an hash-table keyed by Java method name."
  (%jmake-proxy (jclass interface)
		(jmake-invocation-handler 
		 (lambda (obj method &rest args)
		   (let ((fn (gethash method implementation)))
		     (if fn
			 (apply fn obj args)
			 (error "Implementation for method ~A not found in ~A"
				method implementation)))))
		lisp-this))

(defun jobject-class (obj)
  "Returns the Java class that OBJ belongs to"
  (jcall (jmethod "java.lang.Object" "getClass") obj))

(defun jclass-superclass (class)
  "Returns the superclass of CLASS, or NIL if it hasn't got one"
  (jcall (jmethod "java.lang.Class" "getSuperclass") (jclass class)))

(defun jclass-interfaces (class)
  "Returns the vector of interfaces of CLASS"
  (jcall (jmethod "java.lang.Class" "getInterfaces") (jclass class)))

(defun jclass-interface-p (class)
  "Returns T if CLASS is an interface"
  (jcall (jmethod "java.lang.Class" "isInterface") (jclass class)))

(defun jclass-superclass-p (class-1 class-2)
  "Returns T if CLASS-1 is a superclass or interface of CLASS-2"
  (jcall (jmethod "java.lang.Class" "isAssignableFrom" "java.lang.Class")
         (jclass class-1)
         (jclass class-2)))

(defun jclass-array-p (class)
  "Returns T if CLASS is an array class"
  (jcall (jmethod "java.lang.Class" "isArray") (jclass class)))

(defun jarray-component-type (atype)
  "Returns the component type of the array type ATYPE"
  (assert (jclass-array-p atype))
  (jcall (jmethod "java.lang.Class" "getComponentType") atype))

(defun jarray-length (java-array)
  (jstatic "getLength" "java.lang.reflect.Array" java-array)  )

(defun (setf jarray-ref) (new-value java-array &rest indices)
  (apply #'jarray-set java-array new-value indices))

(defun jnew-array-from-array (element-type array)
  "Returns a new Java array with base type ELEMENT-TYPE (a string or a class-ref)
   initialized from ARRAY"
  (flet
    ((row-major-to-index (dimensions n)
                         (loop for dims on dimensions
                           with indices
                           do
                           (multiple-value-bind (m r) (floor n (apply #'* (cdr dims)))
                             (push m indices)
                             (setq n r))
                           finally (return (nreverse indices)))))
    (let* ((fill-pointer (when (array-has-fill-pointer-p array) (fill-pointer array)))
           (dimensions (if fill-pointer (list fill-pointer) (array-dimensions array)))
           (jarray (apply #'jnew-array element-type dimensions)))
      (dotimes (i (if fill-pointer fill-pointer (array-total-size array)) jarray)
        #+maybe_one_day
        (setf (apply #'jarray-ref jarray (row-major-to-index dimensions i)) (row-major-aref array i))
        (apply #'(setf jarray-ref) (row-major-aref array i) jarray (row-major-to-index dimensions i))))))

(defun jclass-constructors (class)
  "Returns a vector of constructors for CLASS"
  (jcall (jmethod "java.lang.Class" "getConstructors") (jclass class)))

(defun jconstructor-params (constructor)
  "Returns a vector of parameter types (Java classes) for CONSTRUCTOR"
  (jcall (jmethod "java.lang.reflect.Constructor" "getParameterTypes") constructor))

(defun jclass-fields (class &key declared public)
  "Returns a vector of all (or just the declared/public, if DECLARED/PUBLIC is true) fields of CLASS"
  (let* ((getter (if declared "getDeclaredFields" "getFields"))
         (fields (jcall (jmethod "java.lang.Class" getter) (jclass class))))
    (if public (delete-if-not #'jmember-public-p fields) fields)))

(defun jclass-field (class field-name)
  "Returns the field named FIELD-NAME of CLASS"
  (jcall (jmethod "java.lang.Class" "getField" "java.lang.String")
         (jclass class) field-name))

(defun jfield-type (field)
  "Returns the type (Java class) of FIELD"
  (jcall (jmethod "java.lang.reflect.Field" "getType") field))

(defun jfield-name (field)
  "Returns the name of FIELD as a Lisp string"
  (jcall (jmethod "java.lang.reflect.Field" "getName") field))


(defun (setf jfield) (newvalue class-ref-or-field field-or-instance
		      &optional (instance nil instance-supplied-p) unused-value)
  (declare (ignore unused-value))
  (if instance-supplied-p
      (jfield class-ref-or-field field-or-instance instance newvalue)
      (jfield class-ref-or-field field-or-instance newvalue)))

(defun jclass-methods (class &key declared public)
  "Return a vector of all (or just the declared/public, if DECLARED/PUBLIC is true) methods of CLASS"
  (let* ((getter (if declared "getDeclaredMethods" "getMethods"))
         (methods (jcall (jmethod "java.lang.Class" getter) (jclass class))))
    (if public (delete-if-not #'jmember-public-p methods) methods)))

(defun jmethod-params (method)
  "Returns a vector of parameter types (Java classes) for METHOD"
  (jcall (jmethod "java.lang.reflect.Method" "getParameterTypes") method))

(defun jmethod-return-type (method)
  "Returns the result type (Java class) of the METHOD"
  (jcall (jmethod "java.lang.reflect.Method" "getReturnType") method))

(defun jmethod-declaring-class (method)
  "Returns the Java class declaring METHOD"
  (jcall (jmethod "java.lang.reflect.Method" "getDeclaringClass") method))

(defun jmethod-name (method)
  "Returns the name of METHOD as a Lisp string"
  (jcall (jmethod "java.lang.reflect.Method" "getName") method))

(defun jinstance-of-p (obj class)
  "OBJ is an instance of CLASS (or one of its subclasses)"
  (and (java-object-p obj)
       (jcall (jmethod "java.lang.Class" "isInstance" "java.lang.Object") (jclass class) obj)))

(defun jmember-static-p (member)
  "MEMBER is a static member of its declaring class"
  (jstatic (jmethod "java.lang.reflect.Modifier" "isStatic" "int")
           "java.lang.reflect.Modifier"
           (jcall (jmethod "java.lang.reflect.Member" "getModifiers") member)))

(defun jmember-public-p (member)
  "MEMBER is a public member of its declaring class"
  (jstatic (jmethod "java.lang.reflect.Modifier" "isPublic" "int")
           "java.lang.reflect.Modifier"
           (jcall (jmethod "java.lang.reflect.Member" "getModifiers") member)))

(defun jmember-protected-p (member)
  "MEMBER is a protected member of its declaring class"
  (jstatic (jmethod "java.lang.reflect.Modifier" "isProtected" "int")
           "java.lang.reflect.Modifier"
           (jcall (jmethod "java.lang.reflect.Member" "getModifiers") member)))

(defmethod make-load-form ((object java-object) &optional environment)
  (declare (ignore environment))
  (let ((class-name (jclass-name (jclass-of object))))
    (cond
     ((string= class-name "java.lang.reflect.Constructor")
      `(java:jconstructor ,(jclass-name
                            (jcall (jmethod "java.lang.reflect.Constructor"
                                            "getDeclaringClass") object))
                          ,@(loop for arg-type across
                              (jcall
                               (jmethod "java.lang.reflect.Constructor"
                                        "getParameterTypes")
                               object)
                              collecting
                              (jclass-name arg-type))))
     ((string= class-name "java.lang.reflect.Method")
      `(java:jmethod ,(jclass-name
                       (jcall (jmethod "java.lang.reflect.Method"
                                       "getDeclaringClass") object))
                     ,(jmethod-name object)
                     ,@(loop for arg-type across
                         (jcall
                          (jmethod "java.lang.reflect.Method"
                                   "getParameterTypes")
                          object)
                         collecting
                         (jclass-name arg-type))))
     ((jinstance-of-p object "java.lang.Class")
      `(java:jclass ,(jcall (jmethod "java.lang.Class" "getName") object)))
     (t
      (error "Unknown load-form for ~A" class-name)))))

(defun jproperty-value (obj prop)
  (%jget-property-value obj prop))

(defun (setf jproperty-value) (value obj prop)
  (%jset-property-value obj prop value))

(provide "JAVA-EXTENSIONS")
