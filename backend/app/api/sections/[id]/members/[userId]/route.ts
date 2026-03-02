import { NextResponse } from 'next/server';
import prisma from '@/lib/db';
import { verifyToken } from '@/lib/auth';

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string, userId: string }> }) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token) as any;
        if (!decoded || decoded.role !== 'TEACHER') {
            return NextResponse.json({ error: 'Only teachers can remove members' }, { status: 403 });
        }

        const { id: sectionId, userId: targetUserId } = await params;

        const section = await prisma.section.findUnique({
            where: { id: sectionId },
            include: { course: true }
        });

        if (!section) return NextResponse.json({ error: 'Section not found' }, { status: 404 });
        if (section.course.teacherId !== decoded.userId) {
            return NextResponse.json({ error: 'Not authorized for this section' }, { status: 403 });
        }

        await prisma.enrollment.deleteMany({
            where: {
                sectionId: sectionId,
                userId: targetUserId
            }
        });

        return NextResponse.json({ message: 'User removed successfully' });

    } catch (error) {
        console.error(error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
