#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

uint32_t s[64] = { 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
                   5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
                   4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
                   6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 };

uint32_t K[64] = { 0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
                   0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
                   0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
                   0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
                   0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
                   0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
                   0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
                   0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
                   0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
                   0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
                   0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
                   0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
                   0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
                   0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
                   0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
                   0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391 };

uint32_t a0 = 0x67452301;
uint32_t b0 = 0xefcdab89;
uint32_t c0 = 0x98badcfe;
uint32_t d0 = 0x10325476;

uint8_t message[64];

#define leftrotate(x, c) (((x) << c) | ((x) >> (32-c)))

int main(int argc, char** argv)
{
    if(read(STDIN_FILENO, message, 50) != 50)
    {
        printf("couldn't read stdin. not enough chars maybe?\n");
        return 1;
    }

    FILE* log = fopen("log.txt", "w");

    // preprocessing
    // 50 bytes are already read
    message[50] = 0x80;
    for (int i = 0; i < 5; i++)
        message[51 + i] = 0;
    uint64_t bit_len = 50*8;
    message[56] = bit_len;
    message[57] = bit_len >> 8;
    message[58] = bit_len >> 16;
    message[59] = bit_len >> 24;
    message[60] = bit_len >> 32;
    message[61] = bit_len >> 40;
    message[62] = bit_len >> 48;
    message[63] = bit_len >> 56;

    uint32_t M[16];
    for (int i = 0, j = 0; i < 16; ++i, j += 4)
        M[i] = (message[j]) + 
               (message[j + 1] << 8) + 
               (message[j + 2] << 16) + 
               (message[j + 3] << 24);

    // let the magic happen
    uint32_t A = a0;
    uint32_t B = b0;
    uint32_t C = c0;
    uint32_t D = d0;
    uint32_t F = 0, dTemp = 0;
    int g = 0;

    for (int i = 0; i < 64; i++)
    {
        if (i <= 15)
        {
            F = (B & C) | (~B & D);
            g = i;
        }
        else if(i <= 31)
        {
            F = (D & B) | (~D & C);
            g = (5*i + 1) % 16;
        }
        else if(i <= 47)
        {
            F = B ^ C ^ D;
            g = (3*i + 5) % 16;
        }
        else
        {
            F = C ^ (B | ~D);
            g = (7*i) % 16;
        }

        dTemp = D;
        D = C;
        C = B;
        B = B + leftrotate(A + F + K[i] + M[g], s[i]);
        A = dTemp;

        fprintf(log, "round: %02d, A: %08x, B: %08x, C: %08x, D: %08x, F: %08x\n",
                i, A, B, C, D, F);
        if (i == 15 || i == 31 || i == 47)
            fprintf(log, "\n");
    }

    a0 += A;
    b0 += B;
    c0 += C;
    d0 += D;

    // little-endian (x86) -> big-endian (md5)
    uint8_t hash[16];
    for (int i = 0; i < 4; ++i)
    {
		hash[i]      = (a0 >> (i * 8)) & 0x000000ff;
		hash[i + 4]  = (b0 >> (i * 8)) & 0x000000ff;
		hash[i + 8]  = (c0 >> (i * 8)) & 0x000000ff;
		hash[i + 12] = (d0 >> (i * 8)) & 0x000000ff;
	}

    printf("%08x %08x %08x %08x\n", a0, b0, c0, d0);

    for (int i = 0; i < 16; i += 4)
        printf("%02x%02x%02x%02x", hash[i + 0], hash[i + 1], hash[i + 2], hash[i + 3]);
    printf("\n");

    return 0;
}

