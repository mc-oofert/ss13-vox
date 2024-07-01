;;  ----------------------------------------------------------------  ;;
;;                 Nagoya Institute of Technology and                 ;;
;;                     Carnegie Mellon University                     ;;
;;                         Copyright (c) 2002                         ;;
;;                        All Rights Reserved.                        ;;
;;                                                                    ;;
;;  Permission is hereby granted, free of charge, to use and          ;;
;;  distribute this software and its documentation without            ;;
;;  restriction, including without limitation the rights to use,      ;;
;;  copy, modify, merge, publish, distribute, sublicense, and/or      ;;
;;  sell copies of this work, and to permit persons to whom this      ;;
;;  work is furnished to do so, subject to the following conditions:  ;;
;;                                                                    ;;
;;    1. The code must retain the above copyright notice, this list   ;;
;;       of conditions and the following disclaimer.                  ;;
;;                                                                    ;;
;;    2. Any modifications must be clearly marked as such.            ;;
;;                                                                    ;;
;;    3. Original authors' names are not deleted.                     ;;
;;                                                                    ;;
;;    4. The authors' names are not used to endorse or promote        ;;
;;       products derived from this software without specific prior   ;;
;;       written permission.                                          ;;
;;                                                                    ;;
;;  NAGOYA INSTITUTE OF TECHNOLOGY, CARNEGIE MELLON UNIVERSITY AND    ;;
;;  THE CONTRIBUTORS TO THIS WORK DISCLAIM ALL WARRANTIES WITH        ;;
;;  REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF      ;;
;;  MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL NAGOYA INSTITUTE   ;;
;;  OF TECHNOLOGY, CARNEGIE MELLON UNIVERSITY NOR THE CONTRIBUTORS    ;;
;;  BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR   ;;
;;  ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        ;;
;;  PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER    ;;
;;  TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR  ;;
;;  PERFORMANCE OF THIS SOFTWARE.                                     ;;
;;                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      Generic HTS support code and specific features                ;;
;;                                                                    ;;
;;             Author :  Alan W Black                                 ;;
;;             Date   :  August 2002                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar hts_synth_pre_hooks nil)
(defvar hts_synth_post_hooks nil)

(defvar hts_duration_stretch 0)
(defvar hts_f0_mean 0)
(defvar hts_f0_std 1)
(defvar hts_fw_factor 0.42)
(defvar hts_total_length 0.0)
(defvar hts_uv_threshold 0.5)
(defvar hts_use_phone_align 0)
(defvar hts_postfilter 0.3)

(defSynthType HTS
    (let ((wdir (make_tmp_filename))
        ffile wfile)

    (system (format nil "mkdir %s" wdir))
    (set! ffile (path-append wdir "utt.feats"))
    (set! wfile (path-append wdir "utt.wav"))
    
    (apply_hooks hts_synth_pre_hooks utt)
    (hts_dump_feats utt cmu_us_kal_com_hts:feats_list ffile)

    (set! hts_command
     (format
	   nil
	   "%s/htsvoice.pl --directory %s --workdir %s --infile %s --outfile %s --duration_factor %f --f0_mean %f --f0_std %f --fw_factor %f --total_length %f --uv_threshold %f --use_phone_align %d --postfilter %f"
	   cmu_us_kal_com_hts::hts_data_dir
	   cmu_us_kal_com_hts::hts_data_dir
	   wdir
	   ffile
	   wfile
	   hts_duration_stretch
	   hts_f0_mean
	   hts_f0_std
	   hts_fw_factor
	   hts_total_length
	   hts_uv_threshold
	   hts_use_phone_align
	   hts_postfilter
	   ))
;    (format t "%s\n" hts_command)
    (system hts_command)

    (utt.import.wave utt wfile)

    (system (format nil "rm -rf %s" wdir))

    (apply_hooks hts_synth_post_hooks utt)
    utt)
)

(define (hts_dump_feats utt feats ofile)
  (let ((ofd (fopen ofile "w")))
    (mapcar
     (lambda (s)
       (mapcar
	(lambda (f)
	  (format ofd "%s " (item.feat s f)))
	feats)
       (format ofd "\n"))
     (utt.relation.items utt 'Segment))
    (fclose ofd)
    ))


;;
;;  Extra features
;;  From Segment items refer by 
;;
;;  R:SylStructure.parent.parent.R:Phrase.parent.lisp_num_syls_in_phrase
;;  R:SylStructure.parent.parent.R:Phrase.parent.lisp_num_words_in_phrase
;;  lisp_total_words
;;  lisp_total_syls
;;  lisp_total_phrases
;;
;;  The last three will act on any item

(define (distance_to_p_content i)
  (let ((c 0) (rc 0 ) (w (item.relation.prev i "Phrase")))
    (while w
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "contentp"))
      (begin
        (set! rc c)
        (set! w nil))
      (set! w (item.prev w)))
      )
    rc))

(define (distance_to_n_content i)
  (let ((c 0) (rc 0) (w (item.relation.next i "Phrase")))
    (while w
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "contentp"))
      (begin
        (set! rc c)
        (set! w nil))
      (set! w (item.next w)))
      )
    rc))

(define (distance_to_p_accent i)
  (let ((c 0) (rc 0 ) (w (item.relation.prev i "Syllable")))
    (while (and w (member_string (item.feat w "syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "accented"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.prev w)))
        )
        rc))

(define (distance_to_n_accent i)
  (let ((c 0) (rc 0 ) (w (item.relation.next i "Syllable")))
    (while (and w (member_string (item.feat w "p.syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "accented"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.next w)))
        )
        rc))

(define (distance_to_p_stress i)
  (let ((c 0) (rc 0 ) (w (item.relation.prev i "Syllable")))
    (while (and w (member_string (item.feat w "syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "stress"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.prev w)))
        )
        rc))

(define (distance_to_n_stress i)
  (let ((c 0) (rc 0 ) (w (item.relation.next i "Syllable")))
    (while (and w (member_string (item.feat w "p.syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "stress"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.next w)))
        )
        rc))

(define (num_syls_in_phrase i)
  (apply 
   +
   (mapcar
    (lambda (w)
      (length (item.relation.daughters w 'SylStructure)))
    (item.relation.daughters i 'Phrase))))

(define (num_words_in_phrase i)
  (length (item.relation.daughters i 'Phrase)))

(define (total_words w)
  (length
   (utt.relation.items (item.get_utt w) 'Word)))

(define (total_syls s)
  (length
   (utt.relation.items (item.get_utt s) 'Syllable)))

(define (total_phrases s)
  (length
   (utt.relation_tree (item.get_utt s) 'Phrase)))

