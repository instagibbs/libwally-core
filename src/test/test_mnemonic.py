import unittest
from util import *

class MnemonicTests(unittest.TestCase):

    words_list, wl = None, None

    def setUp(self):
        if self.wl is None and wordlist_init is not None:
            self.words_list, words = load_words('english')
            self.words_prefix_list = [x[:4] for x in self.words_list]
            self.wl = wordlist_init(utf8(words))


    @internal_only()
    def test_mnemonic(self):

        LEN = 16
        PHRASES = LEN * 8 // 11 # 11 bits per phrase
        PHRASES_BYTES = (PHRASES * 11 + 7) // 8 # Bytes needed to store
        self.assertEqual(LEN, PHRASES_BYTES)

        buf = create_string_buffer(LEN)
        prefix_buf = create_string_buffer(LEN)

        # Test round tripping
        for i in range(len(self.words_list) - PHRASES):
            phrase = utf8(' '.join(self.words_list[i : i + PHRASES]))
            prefix_phrase = utf8(' '.join(self.words_prefix_list[i : i + PHRASES]))

            ret, written = mnemonic_to_bytes(self.wl, phrase, buf, LEN)

            prefix_ret, prefix_written = mnemonic_prefix_to_bytes(self.wl, prefix_phrase, prefix_buf, LEN)

            if prefix_ret != 0:
                continue
            self.assertEqual(ret, 0)
            self.assertEqual(prefix_ret, 0)
            self.assertEqual(written, PHRASES_BYTES)
            self.assertEqual(prefix_written, PHRASES_BYTES)
            generated = mnemonic_from_bytes(self.wl, buf, LEN)
            prefix_generated = mnemonic_from_bytes(self.wl, prefix_buf, LEN)
            self.assertEqual(phrase, generated)
            self.assertEqual(phrase, prefix_generated)

if __name__ == '__main__':
    unittest.main()
