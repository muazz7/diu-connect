import { NextResponse } from 'next/server';
import prisma from '@/lib/db';

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { email, code } = body;

        if (code !== '1234') {
            return NextResponse.json({ error: 'Invalid verification code' }, { status: 400 });
        }

        const user = await prisma.user.update({
            where: { email },
            data: { isVerified: true }
        });

        return NextResponse.json({ message: 'Account verified successfully' });

    } catch (error) {
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
