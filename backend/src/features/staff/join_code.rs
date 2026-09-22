use rand::RngExt;
use sha2::{Digest, Sha256};

/// No I, L, O, 0 or 1: the code is read aloud and typed on a cheap phone, and
/// those are the characters people mix up.
const ALPHABET: &[u8] = b"ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const LENGTH: usize = 10;

/// A single-use code a staff member types to join a store, shown to the owner
/// as `ABCDE-FGHJK`. Ten characters from 31 is about 8 × 10^14 possibilities,
/// which makes guessing a live code for its one day of life impractical.
pub fn generate() -> String {
    let mut rng = rand::rng();
    let raw: String = (0..LENGTH)
        .map(|_| ALPHABET[rng.random_range(0..ALPHABET.len())] as char)
        .collect();
    format!("{}-{}", &raw[..LENGTH / 2], &raw[LENGTH / 2..])
}

/// Accepts the code however it was typed: lower case, with or without the
/// dash, with stray spaces.
pub fn normalise(typed: &str) -> String {
    typed
        .chars()
        .filter(char::is_ascii_alphanumeric)
        .map(|c| c.to_ascii_uppercase())
        .collect()
}

/// Codes are stored hashed, like refresh tokens, so a database leak does not
/// hand out working invitations.
pub fn fingerprint(typed: &str) -> String {
    hex::encode(Sha256::digest(normalise(typed).as_bytes()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_code_is_two_groups_of_unambiguous_characters() {
        let code = generate();

        assert_eq!(code.len(), LENGTH + 1);
        assert_eq!(&code[5..6], "-");
        assert!(
            normalise(&code)
                .bytes()
                .all(|byte| ALPHABET.contains(&byte))
        );
    }

    #[test]
    fn however_it_is_typed_it_matches() {
        let code = "ABCDE-FGHJK";

        assert_eq!(fingerprint(code), fingerprint("abcde fghjk"));
        assert_eq!(fingerprint(code), fingerprint(" ABCDEFGHJK "));
        assert_ne!(fingerprint(code), fingerprint("ABCDE-FGHJM"));
    }

    #[test]
    fn codes_do_not_repeat() {
        let first = generate();
        assert!((0..50).all(|_| generate() != first));
    }
}
