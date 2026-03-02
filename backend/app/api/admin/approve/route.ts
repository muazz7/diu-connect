import { NextResponse } from 'next/server';
import prisma from '@/lib/db';
import { verifyToken } from '@/lib/auth';

export async function POST(request: Request) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token) as any;
        if (!decoded || decoded.role !== 'ADMIN') {
            return NextResponse.json({ error: 'Only admins can approve teachers' }, { status: 403 });
        }

        const body = await request.json();
        const { teacherId } = body;

        await prisma.user.update({
            where: { id: teacherId },
            data: { isVerified: true }
        });

        return NextResponse.json({ message: 'Teacher approved' });

    } catch (error) {
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
